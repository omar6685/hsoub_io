require File.dirname(__FILE__) + '/test_helper'
require "notification"

class NotificationTest < Test::Unit::TestCase
  def test_available_notifiers
    assert_equal ['gmail_notifier', 'sms_notifier', 'growl_notifier', 'popup_notifier'], Notification.available_notifiers
  end
end