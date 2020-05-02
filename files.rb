# frozen_string_literal: true
require 'active_record'
require 'caxlsx'
require 'csv'
require 'net/http'

def reload!
  load File.dirname(__FILE__) + '/gnu_cash.rb'
  load File.dirname(__FILE__) + '/gnu_cash/base.rb'
  load File.dirname(__FILE__) + '/gnu_cash/account.rb'
  load File.dirname(__FILE__) + '/gnu_cash/commodity.rb'
  load File.dirname(__FILE__) + '/gnu_cash/price.rb'
  load File.dirname(__FILE__) + '/gnu_cash/split.rb'
  load File.dirname(__FILE__) + '/gnu_cash/transaction.rb'
  load File.dirname(__FILE__) + '/tasks/situation.rb'
  load File.dirname(__FILE__) + '/tasks/prices.rb'
end
reload!
