class Fund < ActiveRecord::Base

  has_many :cotations, class_name: 'FundCotation'
  has_many :transactions, class_name: 'PortfolioTransaction'

  def refresh_data

    data = Boursorama::Fund.new(url).export

    self.boursorama_id = data[:boursorama_id]
    self.isin = data[:isin]
    self.name = data[:name]
    self.currency = data[:currency]
    self.save!

    append_or_refresh_cotation(data[:cotation_date], data[:cotation])

  end

  def refresh_cotation_history

    history = Boursorama::CotationHistory.new(self.boursorama_id, :weekly).cotation_history

    history.each do |date, value|
      append_or_refresh_cotation(date, value)
    end

    history = Boursorama::CotationHistory.new(self.boursorama_id, :daily).cotation_history

    history.each do |date, value|
      append_or_refresh_cotation(date, value)
    end

    nil

  end

  def cotation_at(date)
    cotations.order("date DESC").where("date <= ?", date).first.value
  end

  def append_or_refresh_cotation(date, value)
    c = cotations.where(date: date).first_or_create
    c.value = Amount.new(value, currency, date)
    c.save!
  end
end
