#!/usr/bin/env ruby
# encoding: utf-8

require 'pony'

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
