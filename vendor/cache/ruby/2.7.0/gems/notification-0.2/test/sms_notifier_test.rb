require File.dirname(__FILE__) + '/test_helper'
require "notification"

class SmsNotifierTest < Test::Unit::TestCase
  def test_notifier
    email = Object.new
    email.expects(:notify).with('some message', :to => '3129531193@teleflip.com', :subject => nil)
    
    sms = SmsNotifier.new(email, '312-953-1193')
    
    sms.notify('some message')
    
    email.verify
  end
end