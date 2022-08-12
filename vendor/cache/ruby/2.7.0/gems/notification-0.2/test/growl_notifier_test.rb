require File.dirname(__FILE__) + '/test_helper'
require "notification"

class GrowlNotifierTest < Test::Unit::TestCase
  def test_default_stuff
    g = Object.new
    Growl.expects(:new).returns(g)
    g.expects(:notify)
    
    growl = GrowlNotifier.new
    growl.notify('help')
    
    g.verify
  end
end