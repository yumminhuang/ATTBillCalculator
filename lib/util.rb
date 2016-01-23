#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'

def load_config_data(file_name)
  # Load data from config file
  data = YAML.load_file(file_name)
  plan = data['plan']
  contacts = data['contacts']
  if contacts.select{|c| c.include?('holder')}.size != 1
    abort('Only one holder is allowed!')
  end
  mail_config = data['mail_config']
  return plan, contacts, mail_config
end
