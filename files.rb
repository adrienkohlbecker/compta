# frozen_string_literal: true

require 'active_record'
require 'caxlsx'
require 'csv'
require 'httparty'

def reload!
  load File.dirname(__FILE__) + '/gnu_cash/base.rb'
  load File.dirname(__FILE__) + '/gnu_cash/account.rb'
  load File.dirname(__FILE__) + '/gnu_cash/commodity.rb'
  load File.dirname(__FILE__) + '/gnu_cash/price.rb'
  load File.dirname(__FILE__) + '/gnu_cash/split.rb'
  load File.dirname(__FILE__) + '/gnu_cash/transaction.rb'
  load File.dirname(__FILE__) + '/tasks/couple.rb'
  load File.dirname(__FILE__) + '/tasks/pension.rb'
  load File.dirname(__FILE__) + '/tasks/prices.rb'
  load File.dirname(__FILE__) + '/tasks/situation.rb'
end
reload!
