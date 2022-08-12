# Generalizes the API for growl and snarl
# it should be easy to add support for more later.
class PopupNotifier
  def initialize(*params)
    if Notification.available_notifiers.include?("growl_notifier")
      @notifier = GrowlNotifier.new(*params)
    elsif Notification.available_notifiers.include?("snarl_notifier")
      @notifier = SnarlNotifier.new(*params)
    else
      raise LoadError("No popup notification system installed\n Try 'sudo gem install ruby-growl' or 'gem install snarl-growl'")
    end
  end
  
  def notify(*params)
    @notifier.notify(*params)
  end
end
