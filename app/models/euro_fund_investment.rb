class EuroFundInvestment < ActiveRecord::Base

  belongs_to :euro_fund
  belongs_to :portfolio

  def amount
    @_amount ||= Amount.new(amount_original, amount_currency, amount_date)
  end

  def amount=(new_amount)

    if new_amount.class != Amount
      raise "Trying to set amount to something other than Amount"
    end

    self.amount_currency = new_amount.currency
    self.amount_date = new_amount.at
    self.amount_original = new_amount.value
  end
end
