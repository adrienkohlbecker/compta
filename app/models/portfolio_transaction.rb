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
