# frozen_string_literal: true
# == Schema Information
#
# Table name: portfolio_transactions
#
#  id              :integer          not null, primary key
#  fund_id         :integer
#  shares          :decimal(15, 5)
#  portfolio_id    :integer
#  done_at         :date
#  amount_original :decimal(15, 5)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  amount_currency :string
#  amount_date     :date
#  fund_type       :string
#  category        :string
#

class PortfolioTransaction < ActiveRecord::Base
  belongs_to :fund, polymorphic: true
  belongs_to :portfolio

  def quotation_when_done
    fund.quotation_at(done_at)
  end

  def amount
    return nil if amount_original.nil?
    @_amount ||= Amount.new(amount_original, amount_currency, amount_date)
  end

  def amount=(new_amount)
    if new_amount.class != Amount
      raise 'Trying to set amount to something other than Amount'
    end

    self.amount_currency = new_amount.currency
    self.amount_date = new_amount.at
    self.amount_original = new_amount.value
  end

  def shareprice
    return nil if shareprice_original.nil?
    @_shareprice ||= Amount.new(shareprice_original, shareprice_currency, shareprice_date)
  end

  def shareprice=(new_shareprice)
    if new_shareprice.class != Amount
      raise 'Trying to set shareprice to something other than Amount'
    end

    self.shareprice_currency = new_shareprice.currency
    self.shareprice_date = new_shareprice.at
    self.shareprice_original = new_shareprice.value
  end
end
