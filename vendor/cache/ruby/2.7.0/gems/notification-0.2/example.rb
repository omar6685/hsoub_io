$: << File.dirname(__FILE__) + '/lib'
require "notification"

gmail = GmailNotifier.new(:name => 'dsls.in.ruby', :password => 'dslsinruby', :to => 'jeremystellsmith@gmail.com')
sms   = SmsNotifier.new(gmail, '404-242-9929')
growl = GrowlNotifier.new

#sms.notify('hey neal, whats up?')
#gmail.notify('hello world')
#growl.notify('holy cow')
