require 'rubygems'

module Notification
  VERSION = "0.2"

  #this is the preferred place to check if a notification system
  #is available
  def self.available_notifiers
    @available_notifiers ||= []
  end
end


%w(gmail sms growl snarl popup).each do |type|
  begin
    type += "_notifier"
    require type
    Notification.available_notifiers << type
  rescue LoadError
    $stderr.puts "#{type} is not available"
  end
end

