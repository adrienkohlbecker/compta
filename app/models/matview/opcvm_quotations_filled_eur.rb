# frozen_string_literal: true
class Matview::OpcvmQuotationsFilledEur < Matview::Base
  def value
    @_value ||= value_original.nil? ? nil : Amount.new(value_original, value_currency, value_date)
  end
end
