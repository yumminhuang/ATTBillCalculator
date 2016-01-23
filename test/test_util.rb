require 'test_helper'

require 'test/unit'

require_relative '../lib/util.rb'

class TestUtil < Test::Unit::TestCase

  def test_load_config
    plan, contacts, mail_config = load_config_data(File.expand_path('../../dat.yml', __FILE__))
    assert(contacts.size >= 1)
    assert_equal(plan.keys, ['public', 'discount', 'data'])
    assert_not_nil(mail_config['attachment'])
    assert_not_nil(mail_config['account']['hostname'])
    assert_not_nil(mail_config['account']['port'])
    assert_not_nil(mail_config['account']['username'])
    assert_not_nil(mail_config['account']['password'])
  end
end
