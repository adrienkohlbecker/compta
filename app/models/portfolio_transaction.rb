class PortfolioTransaction < ActiveRecord::Base
  belongs_to :fund
  belongs_to :portfolio

  def quotation_when_done
    fund.quotation_at(done_at)
  end

  def current_value
    fund.quotation_at(Date.today) * shares
  end

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
