# == Schema Information
#
# Table name: fund_quotations
#
#  id             :integer          not null, primary key
#  fund_id        :integer
#  value_original :decimal(15, 5)
#  date           :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  value_currency :string
#  value_date     :date
#  fund_type      :string
#

class FundQuotation < ActiveRecord::Base
  belongs_to :fund, polymorphic: true

  def value
    @_value ||= Amount.new(value_original, value_currency, value_date)
  end

  def value=(amount)

    if amount.class != Amount
      raise "Trying to set value to something other than Amount"
    end

    self.value_currency = amount.currency
    self.value_date = amount.at
    self.value_original = amount.value
  end
end
