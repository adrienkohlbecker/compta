# frozen_string_literal: true
# == Schema Information
#
# Table name: currencies
#
#  id            :integer          not null, primary key
#  name          :string
#  boursorama_id :string
#  url           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Currency < ActiveRecord::Base
  has_many :quotations, class_name: 'CurrencyQuotation'

  has_one :gnucash_commodity, foreign_key: :mnemonic, primary_key: :name, class_name: 'GnuCash::Commodity'

  def refresh_data
    data = Boursorama::Currency.new(url).export

    self.boursorama_id = data[:boursorama_id]
    self.name = data[:name]
    save!

    append_or_refresh_quotation(data[:quotation_date], data[:quotation])
  end

  def refresh_quotation_history
    transaction do
      history = Boursorama::QuotationHistory.new(boursorama_id, :weekly).quotation_history

      history.each do |date, value|
        append_or_refresh_quotation(date, value)
      end

      history = Boursorama::QuotationHistory.new(boursorama_id, :daily).quotation_history

      history.each do |date, value|
        append_or_refresh_quotation(date, value)
      end
    end

    nil
  end

  def quotation_at(date)
    date = date.is_a?(Date) ? date : Date.parse(date)
    Matview::EurToCurrency.where(date: date, currency_id: id).first.value.in_currency(name, date)
  end

  def append_or_refresh_quotation(date, value)
    quotations.where(date: date).first_or_create.update_attributes(value: value)
  end
end
