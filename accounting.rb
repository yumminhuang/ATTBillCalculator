#!/usr/bin/env ruby
# encoding: utf-8

require 'date'
require 'erb'
require 'nokogiri'
require 'optparse'
require 'pony'
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


class Accountant

  def initialize(plan, contacts)
    @public_money = plan['public']
    @data = plan['data']
    @discount = plan.include?('discount') ? @public_money * plan['discount'] : 0
    @holder_name = contacts.select{|c| c.include?('holder')}.pop.fetch('name')
    @names = Array.new
    contacts.each { |item| @names << item['name'] }
  end

  def get_input
    # Get input from console
    @names.each_with_object({}) do |name, fee_input|
      print "输入#{name}的话费:"
      charge = gets.chomp.to_f
      # Return a Hash of name => charge
      fee_input[name] = charge
    end
  end


  def get_input_for_extra
    # Get input for extra charges
    print '本月流量超额(向上取整)GB:'
    # Extra fee
    extra_fee = 15.0 * gets.chomp.to_i
    # Extra data amount for each person
    extras_amount = @names.each_with_object({}) do |name, extras|
      print "#{name}本月使用MB(未超过 #{@data * 1024 / @names.size }MB 按N/n):"
      amount = gets.chomp
      extras[name] = amount.to_f unless ['N', 'n'].include?(amount)
    end
    [extra_fee, extras_amount]
  end


  def account_for_common(fee_input)
    fees = Hash.new
    public_fee = (@public_money - @discount) / @names.size
    fee_input.each do |name, private_fee|
      fees[name] = [private_fee, public_fee, 0.0, 0] if name != @holder_name
    end
    holder_private = fee_input[@holder_name] - (@public_money - @discount)
    fees[@holder_name] = [holder_private, public_fee, 0.0, 0]
    fees
  end

  def account_for_extra(fees, extra_fee, extras)
    limit_per_member = @data * 1024 / @names.size
    all_extra_amount = extras.values.reduce(:+) - limit_per_member * extras.values.size
    extras.each do |name, amount|
      tmp = extra_fee * (amount - limit_per_member) / all_extra_amount
      fees[name][2] += tmp
      fees[name][3] += amount
    end
    fees
  end

  def account
    fee_input = get_input
    puts "合计:#{fee_input.values.reduce(:+).round(2)}"
    print "本月流量超过 #{@data}GB (y/n)?"
    has_extra = ['Y', 'y'].include? gets.chomp
    if has_extra
      extra_fee, extras = get_input_for_extra
      # Minus extra fee from holder's fee
      fee_input[@holder_name] -= extra_fee
    end
    moneys = account_for_common(fee_input)
    moneys = account_for_extra(moneys, extra_fee, extras) if has_extra
    puts "合计:#{moneys.values.map { |e| e[0..-2]}.flatten.reduce(:+).round(2)}"
    moneys.each_with_object({}) do |(name, m), fees|
      fees[name] = {
        'PrivateFee' => m[0].round(2),
        'PublicFee' => m[1].round(2)
      }
      fees[name]['ExtraFee'] = m[2].round(2) unless m[2].zero?
      fees[name]['ExtraAmount'] = m[3].to_i unless m[3].zero?
      fees[name]['SumFee'] = m[0..-2].reduce(:+).round(2)
    end
  end

end


class MessageRender
  include ERB::Util
  attr_accessor :name, :date, :template

  def initialize(name, fee)
    data = YAML.load_file('dat.yml')
    @translation_dict = data['translations']
    @plan = data['plan']
    @contacts_count = data['contacts'].size
    @name = name
    @fee = fee
    @template = File.new('Message.html.erb').read
  end

  def render()
    ERB.new(@template).result(binding)
  end

  def to_html_message
    return render
  end

  def to_text_message
    return Nokogiri::HTML(render).text
  end
end


class MailSender

  def initialize(mail_config, contacts, fees, dry)
    @config = mail_config
    @contacts = contacts
    @fees = fees
    @dry = dry
  end

  def handle
    Pony.options = pony_options
    send_emails unless emails.empty?
  end

  def pony_options
    mail_opts = mail_options
    mail_opts.merge!(authed_options) if @config['authenticate']
    unless @dry
      mail_opts[:attachments] =
      {"AT&T_Bill.pdf" => File.read(@config['attachment'])}
    end
    return mail_opts
  end

  def emails
    @mails ||= @contacts.each_with_object([]) do |to, res|
      tmp = Hash.new
      tmp[:to] = to['mail']
      # Build message
      message = MessageRender.new(to['name'], @fees[to['name']])
      tmp[:html_body] = message.to_html_message
      tmp[:body] = message.to_text_message
      res << tmp
    end
    return @mails
  end

  def send_emails
    emails.each do |email|
      begin
        Timeout.timeout 20 do
          if @dry
            file_path = "/tmp/#{email[:to]}.txt"
            File.open(file_path, 'w') {|f| f.write(email[:body])}
          else
            Pony.mail(email)
            puts "Sent an email to #{email[:to]}"
          end
        end
      rescue Timeout::Error
        puts "Failed to send the bill to #{email[:to]} due to #{$!.message}."
      end
    end
  end

  def mail_options
  {
    :subject => "【手机费】#{(DateTime.now << 1).mon}月账单",
    :from => "#{@config['fromname']} <#{@config['account']['username']}>",
    :via => @config['via'],
    :charset => 'UTF-8',
    :text_part_charset => 'UTF-8',
    :sender => @config['account']['username'],
  }
  end

  def authed_options
  {
    via_options: {
      :address => @config['account']['hostname'],
      :port => @config['account']['port'],
      :enable_starttls_auto => @config['account']['tls'],
      :user_name => @config['account']['username'],
      :password => @config['account']['password'],
      :authentication => :plain
      }
    }
  end

end

if __FILE__ == $0
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
end
