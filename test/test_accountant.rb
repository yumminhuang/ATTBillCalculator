require 'test_helper'

require 'test/unit'
require_relative '../lib/accountant.rb'

#http://stackoverflow.com/questions/16948645/how-do-i-test-a-function-with-gets-chomp-in-it
class TestAccountant < Test::Unit::TestCase

  def test_initialize
    plan = {'public'=>100.0, 'discount'=>0.17, 'data'=>10}
    contacts = [{'name'=>'Name', 'phone'=>'123', 'mail'=>'name@com'},
                {'name'=>'Holder', 'phone'=>'456', 'mail'=>'holder@com', 'holder'=>true}]
    accounting = Accountant.new(plan, contacts)
    assert_not_nil(accounting)
  end
end
