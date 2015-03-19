# == Schema Information
#
# Table name: opcvm_quotations
#
#  id             :integer          not null, primary key
#  opcvm_fund_id  :integer
#  value_original :decimal(15, 5)
#  date           :date
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  value_currency :string
#  value_date     :date
#

class OpcvmQuotation < ActiveRecord::Base
  belongs_to :fund, class_name: 'OpcvmFund', foreign_key: :opcvm_fund_id

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
