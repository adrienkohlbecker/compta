class OpcvmQuotation < ActiveRecord::Base
  belongs_to :opcvm_fund

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
