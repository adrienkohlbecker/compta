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

    data = Boursorama::Fund.new(url).export
    history = Boursorama::FundCotationHistory.new(data[:cotation_history_url]).cotation_history

    history.each do |date, value|
      append_or_refresh_cotation(date, value)
    end

    nil

  end

  def append_or_refresh_cotation(date, value)
    cotations.where(date: date).first_or_create.update_attributes(value: value)
  end
end
