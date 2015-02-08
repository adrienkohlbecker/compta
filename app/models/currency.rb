class Currency < ActiveRecord::Base

  has_many :quotations, class_name: 'CurrencyQuotation'

  def refresh_data

    data = Boursorama::Currency.new(url).export

    self.boursorama_id = data[:boursorama_id]
    self.name = data[:name]
    self.save!

    append_or_refresh_quotation(data[:quotation_date], data[:quotation])

  end

  def refresh_quotation_history

    history = Boursorama::QuotationHistory.new(self.boursorama_id, :weekly).quotation_history

    history.each do |date, value|
      append_or_refresh_quotation(date, value)
    end

    history = Boursorama::QuotationHistory.new(self.boursorama_id, :daily).quotation_history

    history.each do |date, value|
      append_or_refresh_quotation(date, value)
    end

    nil

  end

  def quotation_at(date)
    quotations.order("date DESC").where("date <= ?", date).first.value.in_currency(name, date)
  end

  def append_or_refresh_quotation(date, value)
    quotations.where(date: date).first_or_create.update_attributes(value: value)
  end
end
