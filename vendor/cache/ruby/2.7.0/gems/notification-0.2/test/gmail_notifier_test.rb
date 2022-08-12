require File.dirname(__FILE__) + '/test_helper'
require "notification"

class GmailNotifierTest < Test::Unit::TestCase
  def xtest_send_to_gmail
    gmail = GmailNotifier.new(:name => 'dsls.in.ruby', :password => 'dslsinruby', :to => 'jeremystellsmith@gmail.com')
    gmail.notify('hello world')
  end
  
  def test_default_stuff
    g = Object.new
    GMailer.expects(:connect).with('user', 'pass').yields(g)
    g.expects(:send).with(:subject => 'Hello World', :body => 'Hello World', :to => 'out@yahoo.com')
    
    gmail = GmailNotifier.new(:name => 'user', :password => 'pass', :to => 'out@yahoo.com')
    gmail.notify("Hello World")
    
    g.verify
    GMailer.verify
  end
  
  def test_set_options_in_notify
    g = Object.new
    GMailer.expects(:connect).yields(g)
    g.expects(:send).with(:subject => 'Sup', :body => 'You', :to => 'in@yahoo.com', :files => ['some.txt', 'who.rb'])
    
    gmail = GmailNotifier.new(:name => 'user', :password => 'pass', :to => 'out@yahoo.com')
    gmail.notify("You", :to => 'in@yahoo.com', :files => ['some.txt', 'who.rb'], :subject => 'Sup')
    
    g.verify
    GMailer.verify
  end
    
end