class OpcvmFund < ActiveRecord::Base

  has_many :quotations, class_name: 'FundQuotation', as: :fund
  has_many :transactions, class_name: 'PortfolioTransaction', as: :fund

  def refresh_data

    data = Boursorama::Fund.new(self.boursorama_id).export

    self.isin = data[:isin]
    self.name = data[:name]
    self.currency = data[:currency]
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
    quotations.order("date DESC").where("date <= ?", date).first.value
  end

  def append_or_refresh_quotation(date, value)
    c = quotations.where(date: date).first_or_create
    c.value = Amount.new(value, currency, date)
    c.save!
  end
end
