require 'gmailer'

class GmailNotifier
  def initialize(options)
    @name, @password = options.delete(:name), options.delete(:password)
    @options = options
  end
  
  def notify(message, options = {})
    options[:body] = message
    options[:subject] = message if !options.has_key? :subject
    @options.each {|k,v| options[k] = v if !options.has_key? k }
    
    GMailer.connect(@name, @password) do |g|
       g.send(options)
    end
  end
end