class Currency < ActiveRecord::Base

  has_many :cotations, class_name: 'CurrencyCotation'

  def refresh_data

    data = Boursorama::Currency.new(url).export

    self.boursorama_id = data[:boursorama_id]
    self.name = data[:name]
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

  def append_or_refresh_cotation(date, value)
    cotations.where(date: date).first_or_create.update_attributes(value: value)
  end
end
