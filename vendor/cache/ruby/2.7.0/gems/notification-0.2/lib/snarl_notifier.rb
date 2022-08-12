require 'snarl'

class SnarlNotifier  
  # valid options:
  #   application: the name of your application
  def initialize(options = {})
    @application = options[:application] || 'ruby-snarl'
  end
  
  # 
  def notify(message, options = {})
    title = options[:title] || "#{@application} notification"
    Snarl.show_message(title,message,options[:icon] || nil, options[:timeout] || Snarl::DEFAULT_TIMEOUT)
  end
end
