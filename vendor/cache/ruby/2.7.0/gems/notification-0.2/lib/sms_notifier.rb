class SmsNotifier
  def initialize(email_notifier, phone)
    @email_notifier, @phone = email_notifier, phone.gsub(/\D/, '')
  end
  
  def notify(message)
    @email_notifier.notify(message, :to => "#{@phone}@teleflip.com", :subject => nil)
  end
end