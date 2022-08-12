require 'ruby-growl'

class GrowlNotifier  
  #Valid options:
  # :application => the name of the application sending the notifications (ruby-growl)
  # :to => the hostname notifications will send to by default (localhost)
  # :notifications => an array of names for the different notifications the application can send ([])
  # :password => the growl network password for the given host (nil)
  def initialize(options = {})
    @application = options[:application] || 'ruby-growl'
    @to = options[:to] || 'localhost'
    @notifications = options[:notifications] 
    @password = options[:password]
  end
  
  # Important warning: unless the user has enabled network notifications,
  # this will throw an error.  It's suggested that you catch this error
  # and entreat your user to enable network notifications in an appropriate fashion.
  # They probably also need to enable remote application registration.
  #
  # Valid options:
  #   :to => the hostname notifications will send to by default (localhost)
  #   :type => the notification type that's being sent ("@application notification")
  #   :password => 
  def notify(message, options = {})
    to = options[:to] || @to
    notification_type = options[:type] || "#{@application} notification"
    notifications =  @notifications || [notification_type]

    #ensures we never get an Unknown Notification error
    notification_type = notifications.first unless notifications.include?(notification_type)
    
    g = Growl.new to, @application, notifications, notifications, @password
    g.notify notification_type, @application, message
  end
end
