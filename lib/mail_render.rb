#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'

require_relative 'util'

##
# This class use the template to render email message body

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
    @template = File.new(File.expand_path('../../Message.html.erb', __FILE__)).read
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
