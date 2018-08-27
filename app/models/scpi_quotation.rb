class ScpiQuotation < ActiveRecord::Base
  belongs_to :fund, class_name: 'ScpiFund', foreign_key: :scpi_fund_id

  def value
    @_value ||= value_original.nil? ? nil : Amount.new(value_original, value_currency, value_date)
  end

  def value=(amount)
    if amount.class != Amount
      raise 'Trying to set value to something other than Amount'
    end

    @_value = amount
    self.value_currency = amount.currency
    self.value_date = amount.at
    self.value_original = amount.value
  end

  def subscription_value
    @_subscription_value ||= subscription_value_original.nil? ? nil : Amount.new(subscription_value_original, subscription_value_currency, subscription_value_date)
  end

  def subscription_value=(amount)
    if amount.class != Amount
      raise 'Trying to set subscription_value to something other than Amount'
    end

    @_subscription_value = amount
    self.subscription_value_currency = amount.currency
    self.subscription_value_date = amount.at
    self.subscription_value_original = amount.value
  end
end
