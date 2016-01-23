#!/usr/bin/env ruby
# encoding: utf-8

require 'date'
require 'erb'
require 'optparse'
# require lib/
Dir['lib/*.rb'].each {|file| require_relative file }


options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: accounting.rb [options]'
  opts.on('-c', '--config FILE', 'Config file') do |f|
    options[:config] = f
  end
  opts.on('-d', '--dryrun', 'Dry Run:') do |v|
    options[:dry] = v
  end
end.parse!

# Load configurations
plan, contacts, mail_config = load_config_data(options[:config] || 'dat.yml')

# Calculate fees
accounting = Accountant.new(plan, contacts)
fees = accounting.account

if options[:dry]
    # Print name and fee
    fees.each do |name, money|
        output = [name]
        output += money.values
        puts output.join("\t")
    end
end

# Send emails
MailSender.new(mail_config, contacts, fees, options[:dry]).handle
