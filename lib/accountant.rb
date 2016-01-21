#!/usr/bin/env ruby
# encoding: utf-8

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
