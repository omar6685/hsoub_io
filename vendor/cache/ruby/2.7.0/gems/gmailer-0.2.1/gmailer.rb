#
# = gmailer.rb: A class for interface to Google's webmail service
#
# Author:: Park Heesob
#
# project home page: http://rubyforge.org/projects/gmailutils
#

DEBUG = false

require  'net/https'

GM_LNK_GMAIL = "/mail/?ui=1"
GM_LNK_HOST =        "mail.google.com"
GM_LNK_LOGIN =        "/accounts/ServiceLoginAuth"
GM_LNK_LOGOUT =       "/mail/?logout"
GM_LNK_ATTACHMENT =          "/mail/?view=att&disp=att"
GM_LNK_ATTACHMENT_ZIPPED =   "/mail/?view=att&disp=zip"

GM_USER_AGENT = "Mozilla/5.0 (X11 U Linux i686 en-US rv:1.4b) Gecko/20040612 Mozilla Firebird/0.9"

GM_STANDARD =      0x001
GM_LABEL =         0x002
GM_CONVERSATION =  0x004
GM_QUERY =         0x008
GM_CONTACT =       0x010
GM_PREFERENCE =    0x020
GM_SHOWORIGINAL =  0x040
GM_CONV_SPAM     = 0x080
GM_CONV_TRASH   =  0x100

GM_ACT_CREATELABEL =  1
GM_ACT_DELETELABEL =  2
GM_ACT_RENAMELABEL =  3
GM_ACT_APPLYLABEL =   4
GM_ACT_REMOVELABEL =  5
GM_ACT_PREFERENCE =   6
GM_ACT_STAR =         7
GM_ACT_UNSTAR =       8
GM_ACT_SPAM =         9
GM_ACT_UNSPAM =       10
GM_ACT_READ =         11
GM_ACT_UNREAD =       12
GM_ACT_TRASH =        13
GM_ACT_DELFOREVER =   14
GM_ACT_ARCHIVE =      15
GM_ACT_INBOX =        16
GM_ACT_UNTRASH =      17
GM_ACT_UNDRAFT =      18
GM_ACT_TRASHMSG =     19     # trash individual message
GM_ACT_DELSPAM =      20     # delete spam, forever
GM_ACT_DELTRASH =     21     # delete trash message, forever

module GMailer 
    VERSION = "0.2.0"
    attr_accessor :connection
    
    # the main class. 
    class Connection 
      @cookie_str
      @login
      @pwd
      @raw             # raw packets
      @contact_raw     # raw packets for address book
      @timezone
      @created
      @proxy_host
      @proxy_port
      @proxy_user
      @proxy_pass        
      
      # Reserved mailbox names
      def gmail_reserved_names 
       ["inbox", "star", "starred", "chat", "chats", "draft", "drafts", 
        "sent", "sentmail", "sent-mail", "sent mail", "all", "allmail", "all-mail", "all mail",
        "anywhere", "archive", "spam", "trash", "read", "unread"]
      end
            
      def encode(str)
        return str if @charset.upcase == 'UTF-8'
        begin
            require 'Win32API'
            str += "\0"
            ostr = "\0" * str.length*2
            multiByteToWideChar = Win32API.new('kernel32','MultiByteToWideChar',['L','L','P','L','P','L'],'L')
            multiByteToWideChar.Call(0,0,str,-1,ostr,str.length*2)
            (ostr.strip + "\0").unpack("S*").pack("U*")
        rescue LoadError
            require 'iconv'
            Iconv::iconv('UTF-8',@charset,str)[0]
        end
      end

      #
      # return GMailer
      # desc Constructor
      #
      def initialize(*param)
         @login = ''
         @pwd = ''
         @raw = {}
         @proxy_host = nil
         @proxy_port = 0
         @proxy_user = nil
         @proxy_pass = nil
         @proxy = false
         @type = 0
         if param.length==1 && param[0].is_a?(Hash)
           param = param[0]
           set_login_info(param[:username]||'',param[:password]||'')
           @proxy_host = param[:proxy_host]
           @proxy = !@proxy_host.nil?
           @proxy_port = param[:proxy_port] || 80
           @proxy_user = param[:proxy_user]
           @proxy_pass = param[:proxy_pass]
           @charset = param[:charset] || 'UTF-8'
         elsif param.length==0
           @charset = 'UTF-8'
         elsif param.length==1
           @charset = param[0]
         elsif param.length==2
           @charset = 'UTF-8'
           set_login_info(param[0],param[1])
         elsif param.length==3
           @charset = param[2]
           set_login_info(param[0],param[1])
         else
           raise ArgumentError, 'Invalid argument'
         end
         raise 'Not connected, verify the credentials.' unless connect_no_cookie
      end

      #
      # return void
      # param string my_login
      # param string my_pwd
      # param int my_tz
      # desc Set GMail login information.
      #
      def set_login_info(my_login, my_pwd, my_tz=0)
          @login = my_login
          @pwd = my_pwd
          @timezone = (my_tz*-60).to_i.to_s
      end

			
      #
      # return bool
      # desc Connect to GMail without setting any session/cookie.
      #
      def connect_no_cookie()

        postdata = "service=mail&Email=" + URI.escape(@login).gsub('=','%3D') + "&Passwd=" + URI.escape(@pwd).gsub('=','%3D') + "&null=Sign%20in&continue=" +
                    URI.escape('https://mail.google.com/mail/?ui=html&amp;zy=l') + "&rm=false&PersistentCookie=yes"

        np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new("www.google.com", 443)
        np.use_ssl = true
        np.verify_mode = OpenSSL::SSL::VERIFY_NONE
        result = ''
        response = nil
        np.set_debug_output($stdout) if DEBUG
        np.start { |http|
          response = http.post(GM_LNK_LOGIN, postdata,{'Content-Type' => 'application/x-www-form-urlencoded','User-agent' => GM_USER_AGENT} )
          result = response.body
        }

        if result.include?("errormsg")
           @cookie_str = ''
           return false
        end

        cookies = __cookies(response['set-cookie'])
        arr = URI::split(response["Location"])
        np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(arr[2], 443)
        np.use_ssl = true
        np.verify_mode = OpenSSL::SSL::VERIFY_NONE
        result = ''
        response = nil
        np.set_debug_output($stdout) if DEBUG
        np.start { |http|
          response = http.get(arr[5]+'?'+arr[7], {'Cookie' => cookies,'User-agent' => GM_USER_AGENT} )
          result = response.body
        }

        if result.include?("Redirecting") && result =~ /url='(.+?)'/
                url = $1.gsub("&amp;","&")
          result = ''
          cookies += ';'+ __cookies(response['set-cookie'])
          response = nil
          np.set_debug_output($stdout) if DEBUG
          np.start { |http|
            response = http.get(url, {'Cookie' => cookies,'User-agent'=> GM_USER_AGENT} )
            result = response.body
          }
        end

        if response["Location"]!=nil 
          arr = URI::split(response["Location"])
          np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(arr[2], 443)
          np.use_ssl = true
          np.verify_mode = OpenSSL::SSL::VERIFY_NONE
          result = ''
          cookies = __cookies(response['set-cookie'])
          response = nil
           np.set_debug_output($stdout) if DEBUG
          np.start { |http|
            response = http.get("http://"+arr[2]+arr[5]+'?'+arr[7], {'Cookie' => cookies,'User-agent' => GM_USER_AGENT} )
            result = response.body
          }          
        end

        if response["Location"]!=nil && result.include?("Moved Temporarily")
          arr = URI::split(response["Location"])
          np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(arr[2], 443)
          np.use_ssl = true
          np.verify_mode = OpenSSL::SSL::VERIFY_NONE
          result = ''
          cookies = __cookies(response['set-cookie'])
          response = nil
           np.set_debug_output($stdout) if DEBUG
          np.start { |http|
            response = http.get("http://"+arr[2]+arr[5]+'?'+arr[7], {'Cookie' => cookies,'User-agent' => GM_USER_AGENT} )
            result = response.body
          }          
        end
        
        @loc = "http://mail.google.com/mail/"
        cookies += ';' + __cookies(response['set-cookie'])
        np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(arr[2], 443)
        np.use_ssl = true
        np.verify_mode = OpenSSL::SSL::VERIFY_NONE
         np.set_debug_output($stdout) if DEBUG
        np.start { |http|
          response = http.get(@loc, {'Cookie' => cookies,'User-agent' => GM_USER_AGENT} )
          result = response.body
        }
        cookies += ';' + __cookies(response['set-cookie'])

        @cookie_str = cookies + ";TZ=" + @timezone

        return true
      end

      #
      # return bool
      # desc Connect to GMail with default session management settings.
      #
      def connect()
        raise 'Not connected, verify the credentials.' unless connect_no_cookie()
      end


      #
      # return bool
      # desc See if it is connected to GMail.
      #
      def connected?
        !@cookie_str.empty?
      end
            
      #
      # return bool
      # param string query
      # desc Fetch contents by URL query.
      #
      def __fetch(query)
        if connected?
          query += "&zv=" + (rand(2000)*2147483.648).to_i.to_s
          np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
          np.set_debug_output($stdout) if DEBUG
          inbox = ''
          np.start { |http|
            response = http.get(GM_LNK_GMAIL + "&" + query,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT })
            inbox = response.body
          }
          if @type == GM_SHOWORIGINAL
            @raw = inbox
          else
            state = 0
            tmp = ''
            inbox.each do |l|
              if /^D\(.*\);$/.match(l)
                state = 0
                tmp += l
              elsif l[0,3]=='D([' 
                state = 1
                tmp += l.chomp
              elsif l[0,2]==');' 
                state = 2 
                tmp += ")\n"
              elsif state == 1
                tmp += l.chomp
              end 
            end                
            inbox = tmp
            matches = inbox.scan(/D\((.*)\)/).flatten
            packets = {}
            matches.each do |x|
              x = unescapeHTML(x)
              tmp = eval(x.gsub(",,",",'',").gsub(",,",",'',").gsub(",]",",'']").gsub('#{','#\{').gsub('#','\#'))
              if (packets[tmp[0]] || (tmp[0]=="mi"||tmp[0]=="mb"||tmp[0]=="di"))
                 if (tmp[0]=="t"||tmp[0]=="ts"||tmp[0]=="a"||tmp[0]=="cl")
                    packets[tmp[0]] += tmp[1..-1]
                 end
                 if (tmp[0]=="mi"||tmp[0]=="mb"||tmp[0]=="di")
                    if packets["mg"]
                       packets["mg"].push(tmp)
                    else
                       packets["mg"] = [tmp]
                    end
                 end
              else
                packets[tmp[0]] = tmp
              end
            end
            if packets["cl"] && packets["cl"].length > 1
              packets["ce"] = []
              for i in 1 .. packets["cl"].length-1
                packets["ce"].push(packets["cl"][i])
              end
            end
            @raw = packets
          end
                  
          true
        else    # not logged in yet
          false
        end
      end
      private :__fetch

      def parse_response(response)
        inbox = response
        state = 0
        tmp = ''
        inbox.each do |l|
          if /^D\(.*\);$/.match(l)
            state = 0
            tmp += l
          elsif l[0,3]=='D([' 
            state = 1
            tmp += l.chomp
          elsif l[0,2]==');' 
            state = 2 
            tmp += ")\n"
          elsif state == 1
            tmp += l.chomp
          end 
        end                
        inbox = tmp
        matches = inbox.scan(/D\((.*)\)/).flatten
        packets = {}
        matches.each do |x|
          x = unescapeHTML(x)
          tmp = eval(x.gsub(",,",",'',").gsub(",,",",'',").gsub(",]",",'']").gsub('#{','#\{').gsub('#','\#'))
          if (packets[tmp[0]] || (tmp[0]=="mi"||tmp[0]=="mb"||tmp[0]=="di"))
             if (tmp[0]=="t"||tmp[0]=="ts"||tmp[0]=="a"||tmp[0]=="cl")
                packets[tmp[0]] += tmp[1..-1]
             end
             if (tmp[0]=="mi"||tmp[0]=="mb"||tmp[0]=="di")
                if packets["mg"]
                   packets["mg"].push(tmp)
                else
                   packets["mg"] = [tmp]
                end
             end
          else
            packets[tmp[0]] = tmp
          end
        end
        if packets["cl"] && packets["cl"].length > 1
          packets["ce"] = []
          for i in 1 .. packets["cl"].length-1
            packets["ce"].push(packets["cl"][i])
          end
        end
        @raw = packets
      end

      #
      # return String
      # param string string
      # desc Unescapes properly Unicode escape characters
      #
      def unescapeHTML(str)
        s = str.gsub(/(\\u(.{4}))/n) {
          match = $1.dup
          match = match[1..match.length]
          res=0
          for i in 0 .. match.reverse!.length-1
            res+= (match[i..i].hex)* 16**i
          end
          res.chr
        }.gsub(/&(.*?);/n) {
          match = $1.dup
          case match
            when /\Aamp\z/ni           then '&'
            when /\Aquot\z/ni          then '\"'
            when /\Agt\z/ni            then '>'
            when /\Alt\z/ni            then '<'
            when /\A#(\d+)\z/n         then Integer($1).chr
            when /\A#x([0-9a-f]+)\z/ni then $1.hex.chr
          end
        }
      end

      #
      # return bool
      # param constant type
      # param mixed box
      # param int pos
      # desc Fetch contents from GMail by type.
      #
      def fetch_box(type, box, pos)
        @type = type
        if connected?
          case type
            when GM_STANDARD
                q = "search=" + URI.escape(box.downcase).gsub('=','%3D') + "&view=tl&start=" + pos.to_s

            when GM_LABEL
                q = "search=cat&cat=" + URI.escape(box.to_s).gsub('=','%3D') + "&view=tl&start=" + pos.to_s

            when GM_CONVERSATION
                pos = "inbox" if (pos.to_s=='' || pos.to_i == 0)
                if gmail_reserved_names.include?(pos.downcase)
                  q = "search="+URI.escape(pos).gsub('=','%3D')+"&ser=1&view=cv"
                else
                  q = "search=cat&cat="+URI.escape(pos).gsub('=','%3D')+"&ser=1&view=cv"
                end
                if (box.is_a?(Array))
                   q += "&th=" + box[0].to_s
                   for i in 1 .. box.length
                      q += "&msgs=" + box[i].to_s
                   end
                else
                   q += "&th=" + box.to_s
                end

            when GM_CONV_SPAM
                q = "search=spam&ser=1&view=cv"
                if (box.is_a?(Array))
                   q += "&th=" + box[0].to_s
                   for i in 1 .. box.length
                      q += "&msgs=" + box[i].to_s
                   end
                else
                   q += "&th=" + box.to_s
                end

            when GM_CONV_TRASH
                q = "search=trash&ser=1&view=cv"
                if (box.is_a?(Array))
                   q += "&th=" + box[0].to_s
                   for i in 1 .. box.length
                      q += "&msgs=" + box[i].to_s
                   end
                else
                   q += "&th=" + box.to_s
                end

            when GM_SHOWORIGINAL
                q = "view=om&th=" + box.to_s

            when GM_QUERY
                q = "search=query&q=" + URI.escape(box.to_s).gsub('=','%3D') + "&view=tl&start=" + pos.to_s

            when GM_PREFERENCE
                q = "view=pr&pnl=g"

            when GM_CONTACT
                if box.downcase == "all"
                   q = "view=cl&search=contacts&pnl=a"
                elsif box.downcase == "search"
                   q = "view=cl&search=contacts&pnl=s&q=" + URI.escape(pos.to_s).gsub('=','%3D')
                elsif box.downcase == "detail"                
                   q = "search=contacts&ct_id=" + URI.escape(pos.to_s).gsub('=','%3D') + "&cvm=2&view=ct"
                elsif box.downcase == "group_detail"
                   q = "search=contacts&ct_id=" + URI.escape(pos.to_s).gsub('=','%3D') + "&cvm=1&view=ctl"
                elsif box.downcase == "group"
                   q = "view=cl&search=contacts&pnl=l"
                else # frequently mailed
                   q = "view=cl&search=contacts&pnl=p"
                end

            else
                q = "search=inbox&view=tl&start=0&init=1"
          end

          __fetch(q)
        else
          false
        end
      end

      #
      # return snapshot
      # param constant type
      # param mixed box
      # param int pos
      # desc Fetch contents from GMail by type.
      #
      def fetch(hash_param)
          type = GM_STANDARD
          box = "inbox"
          pos = 0
          @filter = {}
          hash_param.keys.each do |k|
            case k
              when :label
                type = GM_LABEL
                box = hash_param[k]
              when :standard
                type = GM_STANDARD
                box = hash_param[k]
              when :conversation
                type = GM_CONVERSATION
                box = hash_param[k]
              when :show_original
                type = GM_SHOWORIGINAL
                box = hash_param[k]
              when :preference
                type = GM_PREFERENCE
                box = hash_param[k]
              when :contact
                type = GM_CONTACT
                box = hash_param[k]
                    when :param
                      pos = hash_param[k]
              when :query
                type = GM_QUERY
                box = hash_param[k]
              when :pos
                pos = hash_param[k].to_i
              when :read
                @filter[:read] = hash_param[k]
              when :star
                @filter[:star] = hash_param[k]
              else
                raise ArgumentError, 'Invalid hash argument'
            end
          end
          box = "inbox" unless box
          fetch_box(type,box,pos)
          if type == GM_CONVERSATION                
                  fetch_box(GM_CONV_SPAM,box,pos) if @raw['mg'].nil?
                  fetch_box(GM_CONV_TRASH,box,pos) if @raw['mg'].nil?
          end 
          
          if type == GM_SHOWORIGINAL
              ss = @raw
          else
              ss = snapshot(type)
          end 
          if block_given?
            yield(ss)
          elsif type == GM_CONTACT
            ss.contacts
          else
            ss
          end
      end

      #
      # return message
      # param message id
      # desc Fetch a message with message id
      #
      def msg(msgid)
          m = fetch(:conversation=>msgid).message
          if m.nil? then
            raise ArgumentError, 'Message Not Exist'
          end
            m.connection = self                
          if block_given?
            yield(m)
          else
            m
          end
                
      end
                
      #
      # return string[]
      # param string[] convs
      # param string path
      # desc Save all attaching files of conversations to a path.
      #
      def attachments_of(convs, path)

        if connected?
          if (!convs.is_a?(Array))
             convs = [convs]  # array wrapper
          end
          final = []
          convs.each do |v|
            if v.attachment
               v.attachment.each do |vv|
                  f = path+"/"+vv.filename
                  f = path+"/"+vv.filename+"."+rand(2000).to_s while (FileTest.exist?(f))
                  if attachment(vv.id,v.id,f,false)
                     final.push(f)
                  end
               end
            end
          end
          final
        else
            nil
        end
      end

      #
      # return string[]
      # param string[] convs
      # param string path
      # desc Save all attaching files of conversations to a path.
      #
      def zip_attachments_of(convs, path)

        if connected?
             if (!convs.is_a?(Array))
                convs = [convs]  # array wrapper
             end
             final = []
             convs.each do |v|
                if v.attachment
                  f = path+"/attachment.zip"
                  f = path+"/attachment."+rand(2000).to_s+".zip" while (FileTest.exist?(f))
                  if attachment(v["attachment"][0]["id"],v["id"],f,true)
                     final.push(f)
                  end
                end
             end
             final
        else
          nil
        end
      end

      #
      # return bool
      # param string attid
      # param string msgid
      # param string filename
      # desc Save attachment with attachment ID attid and message ID msgid to file with name filename.
      #
      def attachment(attid, msgid, filename, zipped=false)

          if connected?

             if !zipped
                query = GM_LNK_ATTACHMENT + "&attid=" + URI.escape(attid) + "&th=" + URI.escape(msgid)
             else
                query = GM_LNK_ATTACHMENT_ZIPPED + "&th=" + URI.escape(msgid)
             end

             File.open(filename,"wb") do |f|
                  np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
                  np.start { |http|
                    response = http.get(query,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT })
                    f.write(response.body)
                  }
             end
             true
          else
             false
          end
      end

      #
      # return array of labels
      # desc get label lists
      #
      def labels()
          if connected?
             fetch(:standard=>"inbox") {|s| s.label_list }
          else
             nil
          end
      end

      #
      # return string
      # param string label
      # desc validate label
      #
      def validate_label(label)
          label.strip!
          if label==''
            raise ArgumentError, 'Error: Labels cannot empty string'
          end
          if label.length  > 40
            raise ArgumentError, 'Error: Labels cannot contain more than 40 characters'
          end
          if label.include?('^')
            raise ArgumentError, "Error: Labels cannot contain the character '^'"
          end
          label
      end

      #
      # return boolean
      # param string label
      # desc create label
      #
      def create_label(label)
          if connected?
             perform_action(GM_ACT_CREATELABEL, '', validate_label(label))
          else
             false
          end
      end

      #
      # return boolean
      # param string label
      # desc create label
      #
      def delete_label(label)
          if connected?
             perform_action(GM_ACT_DELETELABEL, '', validate_label(label))
          else
             false
          end
      end

      #
      # return boolean
      # param string old_label
      # param string new_label
      # desc create label
      #
      def rename_label(old_label,new_label)
          if connected?
             perform_action(GM_ACT_RENAMELABEL, '',
                validate_label(old_label) +'^' + validate_label(new_label))
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # param string label
      # desc apply label to message
      #
      def apply_label(id,label)
          if connected?
             perform_action(GM_ACT_APPLYLABEL, id, validate_label(label))
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # param string label
      # desc remove label from message
      #
      def remove_label(id,label)
          if connected?
             perform_action(GM_ACT_REMOVELABEL, id, validate_label(label))
          else
             false
          end
      end

      #
      # return boolean
      # param string hash_param
      # desc remove label from message
      #
      def update_preference(hash_param)
          if connected?
            args = {}
            hash_param.keys.each do |k|
              case k
                when :max_page_size
                  args['p_ix_nt'] = hash_param[k]
                when :keyboard_shortcuts
                  args['p_bx_hs'] = hash_param[k] ? '1' : '0'
                when :indicators
                  args['p_bx_sc'] = hash_param[k] ? '1' : '0'
                when :display_language
                  args['p_sx_dl'] = hash_param[k]
                when :signature
                  args['p_sx_sg'] = hash_param[k]
                when :reply_to
                  args['p_sx_rt'] = hash_param[k]
                when :snippets
                  args['p_bx_ns'] = hash_param[k] ? '0' : '1'
                when :display_name
                  args['p_sx_dn'] = hash_param[k]
               end
             end
             param = '&' + args.to_a.map {|x| x.join('=')}.join('&')
             perform_action(GM_ACT_PREFERENCE,'', param)
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc apply star to a message
      #
      def apply_star(msgid)
          if connected?
             perform_action(GM_ACT_STAR,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc remove star from a message
      #
      def remove_star(msgid)
          if connected?
             perform_action(GM_ACT_UNSTAR,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc report a message as spam
      #
      def report_spam(msgid)
          if connected?
             perform_action(GM_ACT_SPAM,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc report a message as not spam
      #
      def report_not_spam(msgid)
          if connected?
             perform_action(GM_ACT_UNSPAM,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc delete a spam message forever
      #
      def delete_spam(msgid)
          if connected?
             perform_action(GM_ACT_DELSPAM,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc mark a message as read
      #
      def mark_read(msgid)
          if connected?
             perform_action(GM_ACT_READ,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc mark a message as unread
      #
      def mark_unread(msgid)
          if connected?
             perform_action(GM_ACT_UNREAD,msgid, '')
          else
             false
          end
      end

      #
      # return original message string
      # param string msgid
      # desc show original message format
      #
      def show_original(msgid)
        if connected?
          fetch(:show_original=>msgid)
        else
          false
        end
      end

      #
      # return boolean
      # param string msgid
      # desc move a message to trash
      #
      def trash(msgid)
        if connected?
          perform_action(GM_ACT_TRASH,msgid, '')
        else
          false
        end
      end

      #
      # return boolean
      # param string msgid
      # desc move a message from trash to inbox
      #
      def untrash(msgid)
          if connected?
             perform_action(GM_ACT_UNTRASH,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc delete a trash message forever
      #
      def delete_trash(msgid)
          if connected?
             perform_action(GM_ACT_DELTRASH,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc delete a message forever
      #
      def delete_message(msgid)
          if connected?
             perform_action(GM_ACT_DELFOREVER,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc archive a message
      #
      def archive(msgid)
          if connected?
             perform_action(GM_ACT_ARCHIVE,msgid, '')
          else
             false
          end
      end

      #
      # return boolean
      # param string msgid
      # desc archive a message
      #
      def unarchive(msgid)
          if connected?
             perform_action(GM_ACT_INBOX,msgid, '')
          else
             false
          end
      end

      
      #
      # return hash of preference
      # desc get preferences
      #
      def preference()
          if connected?
             fetch(:preference=>"all").preference
          else
             nil
          end
      end

      #
      # return array of messages
      # desc get message lists
      #
      def messages(hash_param)
        if connected?                
          ml = fetch(hash_param).message_list
          @filter.keys.each do |k|
            case k
              when :read
                ml.box = ml.box.find_all { |x| x.read? == @filter[k] }
              when :star
                ml.box = ml.box.find_all { |x| x.star? == @filter[k] }
            end
          end
          ml.connection = self
          if block_given?
            yield(ml)
          else
            ml                   
          end
        else
          nil
        end
      end

      #
      # return string
      # param string query
      # desc Dump everything to output.
      #
      def dump(query)
          page = ''
          if connected?
             query += "&zv=" + (rand(2000)*2147483.648).to_i.to_s
             np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
             np.start { |http|
                response = http.get(GM_LNK_GMAIL + "&" + query,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT })
                page = response.body
             }
          else    # not logged in yet
          
          end
          page
      end

      def stripslashes(string)
        encode(string.gsub("\\\"", "\"").gsub("\\'", "'").gsub("\\\\", "\\"))
      end


      #
      # return bool
      # param string to
      # param string subject
      # param string body
      # param string cc
      # param string bcc
      # param string msg_id
      # param string thread_id
      # param string[] files
      # desc Send GMail.
      #
      def send(*param)
        if param.length==1 && param[0].is_a?(Hash)
          param = param[0]
          from = param[:from] || ''
          to = param[:to] || ''
          subject = param[:subject] || ''
          body = param[:body] || ''
          cc = param[:cc] || ''
          bcc = param[:bcc] || ''
          msg_id = param[:msg_id] || ''
          thread_id = param[:msg_id] || ''
          files = param[:files] || []
          draft = param[:draft] || false
          draft_id = param[:draft_id] || ''
        elsif param.length==10
          to, subject, body, cc, bcc, msg_id, thread_id, files, draft, draft_id = param
        elsif param.length==11
          from, to, subject, body, cc, bcc, msg_id, thread_id, files, draft, draft_id = param
        else
          raise ArgumentError, 'Invalid argument'
        end

        if connected?
           other_emails = fetch(:preference=>"all").other_emails
           if other_emails.length>0
              other_emails.each {|v|
                from = v['email'] if from=='' && v['default'] 
              }
              from = @login + '@gmail.com' if from==''
           else
              from = nil
           end

           postdata = {}
           if draft
              postdata["view"] = "sd"
              postdata["draft"] = draft_id
              postdata["rm"] = msg_id
              postdata["th"] = thread_id
           else
              postdata["view"] = "sm"
              postdata["draft"] = draft_id
              postdata["rm"] = msg_id
              postdata["th"] = thread_id
           end
           postdata["msgbody"] = stripslashes(body)
           postdata["from"] = stripslashes(from) if from 
           postdata["to"] = stripslashes(to)
           postdata["subject"] = stripslashes(subject)
           postdata["cc"] = stripslashes(cc)
           postdata["bcc"] = stripslashes(bcc)

           postdata["cmid"] = 1
           postdata["ishtml"] = param[:ishtml] || 0 

           postdata["at"] = at_value

           boundary = "----#{Time.now.to_i}#{(rand(2000)*2147483.648).to_i}"
           postdata2 = []
           postdata.each {|k,v|
             postdata2.push("Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n")
           }

           files.each_with_index do |f,i|
              content = File.open(f,'rb') { |c| c.read }
              postdata2.push("Content-Disposition: form-data; name=\"file#{i}\"; filename=\"#{File.basename(f)}\"\r\n" +
                "Content-Transfer-Encoding: binary\r\n" +
                "Content-Type: application/octet-stream\r\n\r\n" + content + "\r\n")
           end

           postdata = postdata2.collect { |p|
                 "--" + boundary + "\r\n" + p
           }.join('') + "--" + boundary + "--\r\n"

           np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
           response = nil
           np.set_debug_output($stdout) if DEBUG
           np.start { |http|
             response = http.post(GM_LNK_GMAIL, postdata,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT,'Content-type' => 'multipart/form-data; boundary=' + boundary  } )
           }
           true
        else
           false
        end

      end

      #
      # return bool
      # param constant act
      # param string[] id
      # param string para
      # desc Perform action on messages.
      #
      def perform_action(act, id, para)

        if connected?

          if (act == GM_ACT_DELFOREVER)
            perform_action(GM_ACT_TRASH, id, 0)  # trash it before
          end
          postdata = "act="

          action_codes = ["ib", "cc_", "dc_", "nc_", "ac_", "rc_", "prefs", "st", "xst",
              "sp", "us", "rd", "ur", "tr", "dl", "rc_^i", "ib", "ib", "dd", "dm", "dl", "dl"]
          postdata += action_codes[act] ? action_codes[act] : action_codes[GM_ACT_INBOX]
          if act == GM_ACT_RENAMELABEL then
            paras = para.split('^')
            para = validate_label(paras[0])+'^'+validate_label(paras[1])
          elsif ([GM_ACT_APPLYLABEL,GM_ACT_REMOVELABEL,GM_ACT_CREATELABEL,
               GM_ACT_DELETELABEL,].include?(act))
            para = validate_label(para)
          end
          if ([GM_ACT_APPLYLABEL,GM_ACT_REMOVELABEL,GM_ACT_CREATELABEL,
              GM_ACT_DELETELABEL,GM_ACT_RENAMELABEL,GM_ACT_PREFERENCE].include?(act))
            postdata += para.to_s
          end

          postdata += "&at=" + at_value

          if (act == GM_ACT_TRASHMSG)
            postdata += "&m=" + id.to_s
          else
            if id.is_a?(Array)
              id.each {|t| postdata += "&t="+t.to_s }
            else
              postdata += "&t="+id.to_s
            end
          end
          postdata += "&vp="

          if [GM_ACT_UNTRASH,GM_ACT_DELFOREVER,GM_ACT_DELTRASH].include?(act)
            link = GM_LNK_GMAIL+"&search=trash&view=tl&start=0"
          elsif (act == GM_ACT_DELSPAM)
            link = GM_LNK_GMAIL+"&search=spam&view=tl&start=0"
          else
            link = GM_LNK_GMAIL+"&search=query&q=&view=tl&start=0"
          end

          np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
          np.set_debug_output($stdout) if DEBUG
          np.start { |http|
            response = http.post(link, postdata,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT} )
            result = response.body
          }

          true
        else
          false
        end

      end

      #
      # return void
      # desc Disconnect from GMail.
      #
      def disconnect()

        response = nil
        np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
        np.set_debug_output($stdout) if DEBUG
        np.start { |http|
          response = http.get(GM_LNK_LOGOUT,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT })
        }
        arr = URI::split(response["Location"])
        np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(arr[2], 80)
        np.set_debug_output($stdout) if DEBUG
        np.start { |http|
          response = http.get(arr[5]+'?'+arr[7], {'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT} )
        }

        @cookie_str = ''
      end
  
      #
      # return GMailSnapshot
      # param constant type
      # desc Get GMSnapshot by type.
      #
      def snapshot(type)
        if [GM_STANDARD,GM_LABEL,GM_CONVERSATION,GM_QUERY,GM_PREFERENCE,GM_CONTACT].include?(type)      
           return GMailSnapshot.new(type, @raw, @charset)
        else
           return GMailSnapshot.new(GM_STANDARD, @raw, @charset)  # assuming normal by default
        end
      end

      def snap(type)
        action = GM_STANDARD
        case type
          when :standard
            action = GM_STANDARD
          when :label
            action = GM_LABEL
          when :conversation
            action = GM_CONVERSATION
          when :query
            action = GM_QUERY
          when :preference
            action = GM_PREFERENCE
          when :contact
            action = GM_CONTACT
          else
            raise ArgumentError, 'Invalid type'
        end
        snapshot(action)
      end

      #
      # return bool
      # param string email
      # desc Send Gmail invite to email
      #
      def invite(email)

        if connected?

           postdata = "act=ii&em=" + URI.escape(email)

           postdata += "&at=" + at_value

           link = GM_LNK_GMAIL + "&view=ii"

           np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 443)
           np.use_ssl = true
           np.verify_mode = OpenSSL::SSL::VERIFY_NONE
           np.set_debug_output($stdout) if DEBUG
           np.start { |http|
             response = http.post(link, postdata,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT} )
           }

           true
        else
           false
        end

      end


      def at_value
        val = ''
        cc = @cookie_str.split(';')
        cc.each do |cc_part|
         cc_parts = cc_part.split('=')
         if(cc_parts[0]=='GMAIL_AT')
           val = cc_parts[1]
           break
         end
        end
        val
      end           
                 
      #
      # return string[]
      # desc (Static) Get names of standard boxes.
      #
      def standard_box
          ["Inbox","Starred","Sent","Drafts","All","Spam","Trash"]
      end

      #
      # return string
      # param string header
      # desc (Static Private) Extract cookies from header.
      #
      def __cookies(header)
            return '' unless header
            arr = []
            header.split(', ').each { |x|
              if x.include?('GMT')
                arr[-1] += ", " + x
              else
                arr.push x
              end
            }
           arr.delete_if {|x| x.include?('LSID=EXPIRED') }
           arr.map! {|x| x.split(';')[0]}
           arr.join(';')
      end

      def edit_contact(contact_id, name, email, notes, details=[]) 
        if connected?
           postdata = {}
           postdata["act"]   = "ec"
           postdata["ct_id"]  = contact_id.to_s
           postdata["ct_nm"]  = name
           postdata["ct_em"]  = email
           postdata["ctf_n"]  = notes
    
          if (details.length > 0) 
            i = 0        # the detail number
            det_num = '00'  # detail number padded to 2 numbers for gmail
            details.each do |detail1|
              postdata["ctsn_#{det_num}"] = "Unnamed"  # default name if none defined later
              address = ''                # default address if none defined later
              k = 0                        # the field number supplied to Gmail
              field_num = '00'            # must be padded to 2 numbers for gmail
              detail1.each do |key,value|
                field_type = ''
                case key
                  when :phone
                    field_type = "p"
                  when :email
                    field_type = "e"
                  when :mobile
                    field_type = "m"
                  when :fax
                    field_type = "f"                    
                  when :pager
                    field_type = "b"
                  when :im
                    field_type = "i"
                  when :company
                    field_type = "d"
                  when :position
                    field_type = "t"  # t = title
                  when :other
                    field_type = "o"
                  when :address
                    field_type = "a"
                  when :detail_name
                    field_type = "xyz"
                  else
                    field_type = "o"
                end
                if (field_type == "xyz") 
                  postdata["ctsn_#{det_num}"] = value
                elsif (field_type == "a") 
                  address = value
                else 
                  # e.g. ctsf_00_00_p for phone
                  postdata["ctsf_#{det_num}_#{field_num}_#{field_type}"] = value
                  # increments the field number and pads it
                  k = k + 1
                  field_num = "%02d" % k
                end
              end        
              # Address field needs to be last
              # if more than one address was given, the last one found will be used
              if (address != '') 
                postdata["ctsf_#{det_num}_#{field_num}_a"] = address
              end
    
              # increment detail number
              i = i + 1
              det_num = "%02d" % i
            end
          end
  
          postdata["at"] = at_value
          
          postdata2 = []
          postdata.each {|k,v|
             postdata2.push("#{k}=#{v}")
          }
          postdata = postdata2.join('&')
          
          link = GM_LNK_GMAIL + "&view=up"

          np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
          np.set_debug_output($stdout) if DEBUG
          np.start { |http|
            response = http.post(link, postdata,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT} )
            parse_response(response.body)
          }

          orig_contact_id = contact_id.to_i
          if (orig_contact_id == "-1" && @raw["ar"][1])
            if (@raw["cov"][1][1]) 
              contact_id = @raw["cov"][1][1]
            elsif (@raw["a"][1][1]) 
              contact_id = @raw["a"][1][1]
            elsif (@raw["cl"][1][1])
              contact_id = @raw["cl"][1][1]
            end
          end

          status = @raw["ar"][1]==1
          message = @raw["ar"][2]
          raise message unless status
      
          return status      
        else 
          raise "Not connected"
           return false
         end
       end

      def add_contact(name, email, notes, details=[]) 
        edit_contact(-1,name, email, notes, details)
      end
      
      def add_sender_to_contact(message_id) 
        if connected?      
          query  = ''
          query += "&search=inbox"
          query += "&view=up"
          query += "&act=astc"
          query += "&at="+at_value
          query += "&m="+message_id.to_s
   
          np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
          np.set_debug_output($stdout) if DEBUG
          np.start { |http|
            response = http.get(GM_LNK_GMAIL + "&" + query,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT })
          }
   
          return true
        else 
          return false
        end
      end
      
      def delete_contact(id) 
        if connected?          
          query    = ''
      
          if id.is_a?(Array)
            #Post: act=dc&at=xxxxx-xxxx&cl_nw=&cl_id=&cl_nm=&c=0&c=3d
            $query += "&act=dc&cl_nw=&cl_id=&cl_nm="
            id.each { |contact_id|
              query += "&c="+contact_id
            }
          else 
            query   += "search=contacts"
            query   += "&ct_id="+id.to_s
            query   += "&cvm=2"
            query   += "&view=up"
            query   += "&act=dc"
          end
      
          query += "&at="+at_value
          if !(id.is_a?(Array))
            query += "&c="+id.to_s
          end

          np = Net::HTTP::Proxy(@proxy_host,@proxy_port,@proxy_user,@proxy_pass).new(GM_LNK_HOST, 80)
          response = nil
          np.set_debug_output($stdout) if DEBUG      
          if (id.is_a?(Array))
            np.start { |http|
              response = http.post(GM_LNK_GMAIL+"&view=up", query,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT} )
              parse_response(response.body)
            }          
          else 
            np.start { |http|
              response = http.get(GM_LNK_GMAIL + "&" + query,{'Cookie' => @cookie_str,'User-agent' => GM_USER_AGENT })
              parse_response(response.body)
            }          
          end
          
          status = @raw["ar"][1]==1
          message  = @raw["ar"][2]
          raise message unless message
          return status
        else 
          return false
        end
      end      
            
    end

    class GMailSnapshot

      GM_STANDARD =      0x001
      GM_LABEL =         0x002
      GM_CONVERSATION =  0x004
      GM_QUERY =         0x008
      GM_CONTACT =       0x010
      GM_PREFERENCE =    0x020

      def decode(str)
        return str if @charset.upcase == 'UTF-8'
        begin
            require 'Win32API'
            str = str.unpack("U*").pack("S*") + "\0"          
            ostr = "\0" * str.length*2
            wideCharToMultiByte = Win32API.new('kernel32','WideCharToMultiByte',['L','L','P','L','P','L','L','L'],'L')
            wideCharToMultiByte.Call(0,0,str,-1,ostr,str.length*2,0,0)
            ostr.strip
        rescue LoadError
            require 'iconv'
            Iconv::iconv(@charset,'UTF-8',str)[0]
        end
      end

      def strip_tags(str,allowable_tags='')
        str.gsub(/<[^>]*>/, '')
      end

      #
      # return GMailSnapshot
      # param constant type
      # param array raw
      # desc Constructor.
      #
      attr_reader :gmail_ver, :quota_mb, :quota_per, :preference
      attr_reader :std_box_new, :have_invit, :label_list, :label_new
      attr_reader :message_list
      attr_reader :message
      attr_reader :contacts, :other_emails

      def initialize(type, raw, charset='UTF-8')
        @charset = charset
        if (!raw.is_a?(Hash))
           @created = 0
           return nil
        elsif (raw.empty?)
           @created = 0
           return nil
        end
        if [GM_STANDARD,GM_LABEL,GM_CONVERSATION,GM_QUERY].include?(type)
          @gmail_ver = raw["v"][1]
          if raw["qu"]
            @quota_mb = raw["qu"][1]
            @quota_per = raw["qu"][3]
          end
          if (!raw["ds"].is_a?(Array))
             @created = 0
            return nil
          end
          @std_box_new = raw["ds"][1..-1]

          @have_invit = raw["i"][1]
          @label_list = []
          @label_new = []
          raw["ct"][1].each {|v|
            @label_list.push(v[0])
            @label_new.push(v[1])
          }
          if raw["ts"]
            @view = (GM_STANDARD|GM_LABEL|GM_QUERY)
            @message_list = MessageList.new(raw["ts"][5],raw["ts"][3],raw["ts"][1])
          end
          @box = []
          if raw["t"]
            raw["t"].each do |t|
              if (t != "t")
                b = Box.new
                b.id = t[0]
                b.is_read = (t[1] != 1 ? 1 : 0)
                b.is_starred = (t[2] == 1 ? 1 : 0)
                b.date = decode(strip_tags(t[3]))
                b.sender = decode(strip_tags(t[4]))
                b.flag = t[5]
                b.subject = decode(strip_tags(t[6]))
                b.snippet = decode(t[7].gsub('&quot;','"').gsub('&hellip;','...'))
                b.labels = t[8].empty? ? [] : t[8].map{|tt|decode(tt)}
                b.attachment = t[9].empty? ? []: decode(t[9]).split(",")
                b.msgid = t[10]                          
                @box.push(b)
              end
            end
          end

          if raw["cs"]
            @view = GM_CONVERSATION
            @conv_title = raw["cs"][2]
            @conv_total = raw["cs"][8]
            @conv_id = raw["cs"][1]
            @conv_labels = raw["cs"][5].empty? ? '' : raw["cs"][5]
            if !@conv_labels.empty?
              ij = @conv_labels.index("^i")
              if !ij.nil?
                 @conv_labels[ij] = "Inbox"
              end
              ij = @conv_labels.index("^s")
              if !ij.nil?
                 @conv_labels[ij] = "Spam"
              end
              ij = @conv_labels.index("^k")
              if !ij.nil?
                 @conv_labels[ij] = "Trash"
              end
              ij = @conv_labels.index("^t")
              if !ij.nil?
                 @conv_labels[ij] = ''   # Starred
              end
              ij = @conv_labels.index("^r")
              if !ij.nil?
                 @conv_labels[ij] = "Drafts"
              end
            end

            @conv_starred = false
                     
            @conv = []
            b = Conversation.new
            raw["mg"].each do |r|
              if (r[0] == "mb")
                b.body = '' if b.body.nil?
                b.body += r[1]
                if (r[2] == 0)                         
                  b.body = decode(b.body)
                  @conv.push(b)
                  b = Conversation.new
                end
              elsif (r[0] == "mi")
                if b.id
                  @conv.push(b)
                  b = Conversation.new
                end
                b = Conversation.new
                b.index = r[2]
                b.id = r[3]
                b.is_star = r[4]                         
                @conv_starred = (b.is_star == 1)
                b.sender = decode(r[6])
                b.sender_email = r[8].gsub("\"",'')   # remove annoying d-quotes in address
                b.recv = r[9]
                b.recv_email = r[11].to_s.gsub("\"",'')
                b.reply_email = r[14].to_s.gsub("\"",'')
                b.dt_easy = r[10]
                b.dt = r[15]
                b.subject = decode(r[16])
                b.snippet = decode(r[17])
                b.attachment = []
                r[18].each do |bb|
                  at = Attachment.new
                  at.id = bb[0]
                  at.filename = bb[1]
                   at.type = bb[2]
                   at.size = bb[3]
                   b.attachment.push(at)
                end
                b.is_draft = false
                b.body = ''
              elsif (r[0] == "di")
                if b.id
                   @conv.push(b)
                   b = Conversation.new
                end
                b = Conversation.new
                b.index = r[2]
                b.id = r[3]
                b.is_star = r[4]
                @conv_starred =  (b.is_star == 1)
                b.sender = decode(r[6])
                b.sender_email = r[8].gsub("\"",'')    # remove annoying d-quotes in address
                b.recv = r[9]
                b.recv_email = r[11].gsub("\"",'')
                b.reply_email = r[14].gsub("\"",'')
                b.cc_email =  r[12].gsub("\"",'')
                b.bcc_email = r[13].gsub("\"",'')
                b.dt_easy = r[10]
                b.dt = r[15]
                b.subject = decode(r[16])
                b.snippet = decode(r[17])
                b.attachment = []
                r[18].each  do |bb|
                  at = Attachment.new
                  at.id = bb[0]
                  at.filename = bb[1]
                  at.type = bb[2]
                  at.size = bb[3]
                  b.attachment.push(at)                             
                end
                b.is_draft = true
                b.draft_parent = r[5]
                b.body = decode(r[20])
               end
              end
              @conv.push(b) unless !b.id.nil?
              @message = Message.new(@conv_tile,@conv_total,@conv_id,@conv_labels,@conv_starred)
              @message.conv = @conv
            end
          elsif type == GM_CONTACT
            @contacts = []
            @contacts_groups = []
            @contacts_total = 0
            
            if raw["cls"]
              @contacts_total = (raw["cls"][1]).to_i
              @contacts_shown = (raw["cls"][3]).to_i
            end
                     
            type = ''
            c_grp_det = ''
            if raw["a"]
              c_array = "a"
              # determine is this is a list or contact detail
              if ((raw["a"]).length == 2 && raw["a"][1][6]) 
                type      = "detail"
                c_id      = 0
                c_name    = 1
                c_email   = 3
                c_groups  = 4
                c_notes   = 5
                c_detail  = 6
              else 
                c_email   = 3
                c_notes   = 4
                type      = "list"
              end
            elsif raw["cl"]        # list
              c_array     = "cl"
              c_email     = 4
              c_notes     = 5
              c_addresses = 6
              type        = "list"
              elsif raw["cov"]        # contact detail in accounts using "cl"
                c_array   = "cov"
                type      = "detail"
                c_id      = 1
                c_name    = 2
                c_email   = 4
                c_groups  = 6
                c_notes   = 7
                c_detail  = 8
            elsif raw["clv"]         # group detail in accounts using "cl" 
              c_array     = "clv"
              type        = "detail"
              c_id        = 1
              c_name      = 2
              c_email     = 6
              c_total     = 3
              c_detail    = 5
              c_members   = 4
              c_notes     = 0
            else 
              c = Contact.new
              c.id = 'error'
              c.name = 'gmailer Error'
              @contacts.push(c)
            end

            if type == "list"
              # An ordinary list of contacts
              for i in (1 ... raw[c_array].length)                
                a = raw[c_array][i]
                b = Contact.new
                b.id = a[1] # contact id
                b.name = a[2] ? a[2] : ''
                b.email = a[c_email]
                
                if a[c_notes] 
                  if (a[c_notes]).is_a?(Array)
                    b.notes = ''
                    b.is_group = true
                    # email addresses for groups are in a different location and format
                    # "Name" <email@address.net>, "Name2" <email2@address.net>, etc
                    # and needs to be "simply" re-created for backwards compatibility
                    gr_count = a[c_notes].length
                    group_addresses = []
                    a[c_notes].each {|gr_entry|
                      group_addresses.push(gr_entry[1])
                    }                                                                                
                    b.email        = group_addresses.join(", ")
    
                    b.group_names = a[c_email]
                    b.group_total = a[3]
                    b.group_email = (a[c_notes]).length > 0 ? a[c_addresses] : []
                else 
                  b.notes = a[c_notes]
                  b.is_group = false
                  b.groups = a[c_addresses]
                  end
                end
                @contacts.push(b)
              end
            elsif type == "detail"
              details = {}
              if c_array == "clv"
                # Group details
                cov = Contact.new
                cov.is_group   = true                                 # is this a group?
                cov.id         = raw[c_array][1][c_id]                # group id
                cov.name       = raw[c_array][1][c_name]              # group name
                gr_count = (raw[c_array][1][c_detail]).length
                cov.group_names = raw[c_array][1][c_members]   # string of names of group members
                cov.group_total = raw[c_array][1][c_total]     # string, total number of members in group
                cov.group_email = raw[c_array][1][c_email] ? raw[c_array][1][c_email] : ''        # formatted list of addresses as: Name <address>
                cov.notes       = ''                                                    # no notes for groups... yet!
                group_addresses = []                                                    # string of flattened email addresses
                cov.members = []                                                        # array of group members
                (raw[c_array][1][c_detail]).each do |gr_entry|
                  group_addresses.push(gr_entry[1])
                  m = Member.new
                  m.id      = gr_entry[0]
                  m.name    = (gr_entry[2] ? gr_entry[2] : '')
                  m.email   = gr_entry[1]                  
                  cov.members.push(m)                                                                
                end
                cov.email = (group_addresses.length > 0) ? group_addresses.join(", ") : ''
    
              else
                # Contact details (advanced contact information)
                # used when a contact id was supplied for retrieval
                cov = Contact.new
                cov.is_group = false
                cov.id       = raw[c_array][1][c_id]
                cov.name     = raw[c_array][1][c_name]
                cov.email    = raw[c_array][1][c_email]
                cov.groups   = raw[c_array][1][c_groups]
                if raw[c_array][1][c_notes][0]
                  cov.notes = (raw[c_array][1][c_notes][0] == "n") ? raw[c_array][1][c_notes][1] : ''
                else 
                  cov.notes = ''
                end
                num_details = (raw[c_array][1][c_detail]).length
                if num_details > 0 
                  raw[c_array][1][c_detail].each do |i|
                    details[:detail_name] = i[0]
                    temp = i[1] ? i[1] : []
                    0.step(temp.length-1,2) do |j|
                      case temp[j]
                        when "p"
                          field = :phone
                        when "e"
                          field = :email
                        when "m"
                          field = :mobile
                        when "f"
                          field = :fax
                        when "b"
                          field = :pager
                        when "i"
                          field = :im
                        when "d"
                          field = :company
                        when "t"
                          field = :position
                        when "o"
                          field = :other
                        when "a"
                          field = :address
                        end
                      
                        details[field] = temp[j+1]
                      end
            
                  end

                end
                cov.details = details
              end

              @contacts.push(cov)
            end

            # Contact groups
            if raw["cla"]
              for i in (1...(raw["cla"][1]).length)
                a = raw["cla"][1][i]
                b = {
                  :id        => a[0],
                  :name      => a[1],
                  :addresses => a[2] ? a[2] : ''
                }
                @contacts_groups.push(b)                                                  
              end                          
            end
            @view = GM_CONTACT
          elsif type == GM_PREFERENCE
            prefs = {}
            raw["p"].each_with_index { |v,i|
                prefs[v[0]] = v[1] if i>0
            }
            @preference = Preference.new
            prefs.each do |k,v|
              case k
                when 'ix_nt'
                  @preference.max_page_size = v
                when 'bx_hs'
                  @preference.keyboard_shortcuts = (v == '1')
                when 'bx_sc'
                  @preference.indicators = (v == '1')
                when 'sx_dl'
                  @preference.display_language = v
                when 'sx_sg'
                  @preference.signature = (v == '0') ? '' : v
                when 'sx_rt'
                  @preference.reply_to = v
                when 'bx_ns'
                  @preference.snippets = (v == '0')
                when 'sx_dn'
                  @preference.display_name = v
              end
            end
 
            @label_list = []
            @label_total = []
            raw["cta"][1].each { |v|
              @label_list.push(v[0])
              @label_total.push(v[1])
            }
            @other_emails = []
            if raw["cfs"]
               raw["cfs"][1].each {|v|                    
                 @other_emails.push({"name"=>decode(v[0]),"email"=>v[1],"default"=>(v[2]==1)})
               }
            end 
            @filter = []
            raw["fi"][1].each do |fi|
              f = Filter.new
              f.id = fi[0]
              f.query = fi[1]
              f.star = fi[3]
              f.label = fi[4]
              f.archive = fi[5]
              f.trash = fi[6] 
              f.from = fi[2][0]
              f.to = fi[2][1]
              f.subject = fi[2][2]
              f.has = fi[2][3]
              f.hasnot = fi[2][4]
              f.attach = fi[2][5]

              @filter.push(b)
            end
            @view = GM_PREFERENCE
          else
            @created = 0
            return nil
          end
        @message_list.box = @box if @message_list
                
        @created = 1
      end

    end

    # a single filter
    class Filter
      attr_accessor :id,:query,:star,:label,:archive,:trash
      attr_accessor :from,:to,:subject,:has,:hasnot,:attach
    end
      
    # a single box        
    class Box
      attr_accessor :id, :is_read, :is_starred, :date, :msgid        
      attr_accessor :sender, :flag, :subject, :snippet, :labels, :attachment

      def read?
        is_read == 1
      end
              
      def new?
        is_read != 1
      end
              
      def star?
        is_starred == 1
      end
              
    end
      
    # a list of messages.
    class MessageList
      attr_reader :name, :total, :pos
      attr_accessor :box, :connection
      def initialize(name,total,pos)
         @name = name
         @total = total
         @pos = pos
      end
      
      def each(&block)                                    
         @box.each do |b| 
           block.call(b) 
         end 
      end
      
      def each_msg(&block)                                    
        @box.each do |b| 
          m = connection.fetch(:conversation=>b.id).message
          m.connection = @connection
          block.call(m) 
        end 
      end
              
    end
      
    # a Preference
    class Preference
      attr_accessor :max_page_size, :keyboard_shortcuts, :indicators, :display_language
      attr_accessor :signature, :reply_to, :snippets, :display_name

      def initialize
        @max_page_size = '10'
        @keyboard_shortcuts = false
        @indicators = false
        @display_language = 'en'
        @signature = ''
        @reply_to = ''
        @snippets = false
        @display_name = ''
      end         
    end

    # Contact
    class Contact
      attr_accessor :id,:name,:email,:is_group,:notes,:groups,:group_names,:group_email,:group_total,:members,:details
      def initialize
        @id = ''
        @name = ''
        @email = ''
        @notes = ''
        @groups = ''
        @group_names = ''
        @group_email = ''
        @group_total = ''
        @members = ''
        @is_group = false
        @details = {}
      end         
      
      def group?
        @is_group
      end
    end

    # a silgle Member
    class Member
      attr_accessor :id,:name,:email
      def initialize
        @id = ''
        @name = ''
        @email = ''
      end         
    end

    # a single attachment
    class Attachment
      attr_accessor :id, :filename, :type, :size
    end 
      
    # a single conversation
    class Conversation
      attr_accessor :id, :index, :body, :draft_parent, :is_draft, :attachment
      attr_accessor :snippet, :subject, :dt, :dt_easy, :bcc_email, :cc_email
      attr_accessor :reply_email, :recv_email, :recv, :sender_email, :sender, :is_star
      def read?
        is_read == 1
      end
      
      def new?
        is_read != 1
      end
      
      def star?
        is_starred == 1
      end
              
    end 
              
    # a single message 
    class Message
      attr_reader :title, :total, :id, :labels, :starred
      attr_accessor :conv, :connection
      def initialize(title,total,id,labels,starred)
        @title = title
        @total = total
        @id = id
        @labels = labels
        @starred = starred                        
      end
          
      def method_missing(methId)
        str = methId.id2name
        @conv[0].method(str).call
      end

      #
      # return boolean
      # param string label
      # desc apply label to message
      #
      def apply_label(label)
        @connection.perform_action(GM_ACT_APPLYLABEL, @id, label)
      end
          
      #
      # return boolean
      # param string label
      # desc remove label from message
      #
      def remove_label(label)
          @connection.perform_action(GM_ACT_REMOVELABEL, @id, label)
      end

      #
      # return boolean
      # desc apply star to a message
      #
      def apply_star()
        @connection.perform_action(GM_ACT_STAR,@id, '')
      end
      
      #
      # return boolean
      # param string msgid
      # desc remove star from a message
      #
      def remove_star()
        @connection.perform_action(GM_ACT_UNSTAR,@id, '')
      end
          
      #
      # return boolean
      # desc archive a message
      #
      def archive()
        @connection.perform_action(GM_ACT_ARCHIVE,@id, '')
      end
      
      #
      # return boolean
      # param string msgid
      # desc archive a message
      #
      def unarchive()
        @connection.perform_action(GM_ACT_INBOX,@id, '')
      end
      
      #
      # return boolean
      # param string msgid
      # desc mark a message as read
      #
      def mark_read()
        @connection.perform_action(GM_ACT_READ,@id, '')
      end
          
      #
      # return boolean
      # param string msgid
      # desc mark a message as unread
      #
      def mark_unread()
          @connection.perform_action(GM_ACT_UNREAD,@id, '')
      end
      
      def read?()
        @conv[0].read?
      end
          
      def new?()
        @conv[0].new?
      end
          
      #
      # return boolean
      # param string msgid
      # desc report a message as spam
      #
      def report_spam()
        @connection.perform_action(GM_ACT_SPAM,@id, '')
      end
          
      #
      # return boolean
      # param string msgid
      # desc report a message as not spam
      #
      def report_not_spam()
        @connection.perform_action(GM_ACT_UNSPAM,@id, '')
      end
      
      #
      # return boolean
      # desc move a message to trash
      #
      def trash()
        @connection.perform_action(GM_ACT_TRASH,@id, '')
      end
      
      #
      # return boolean
      # desc move a message from trash to inbox
      #
      def untrash()
        @connection.perform_action(GM_ACT_UNTRASH,@id, '')
      end
              
      #
      # return boolean
      # desc delete a message forever
      #
      def delete()
        if connected?
          @connection.perform_action(GM_ACT_DELFOREVER,@id, '')
        else
          false
        end
      end
          
      def original()
        @connection.fetch(:show_original=>@id)
      end
    end

  # Singleton method
  # return bool
  # desc Connect to GMail with default session management settings.
  #

  def GMailer.connect(*param)
    g = Connection.new(*param)
    @connection = g
    if block_given?
      yield(g)
      g.disconnect()
    else
      g
    end
  end

end

