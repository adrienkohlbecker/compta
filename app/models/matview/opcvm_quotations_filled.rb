class Matview::OpcvmQuotationsFilled < Matview::Base
  def value
    @_value ||= Amount.new(value_original, value_currency, value_date)
  end
end
