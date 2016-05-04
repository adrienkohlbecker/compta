# == Schema Information
#
# Table name: opcvm_funds
#
#  id            :integer          not null, primary key
#  isin          :string
#  name          :string
#  boursorama_id :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  currency      :string
#

class OpcvmFund < ActiveRecord::Base

  has_many :quotations, class_name: 'OpcvmQuotation'
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

    transaction do

      history = Boursorama::QuotationHistory.new(self.boursorama_id, :weekly).quotation_history

      history.each do |date, value|
        append_or_refresh_quotation(date, value)
      end

      history = Boursorama::QuotationHistory.new(self.boursorama_id, :daily).quotation_history

      history.each do |date, value|
        append_or_refresh_quotation(date, value)
      end

    end

    nil

  end

  def quotation_at(date)
    Matview::OpcvmQuotationsFilled.where(date: date, opcvm_fund_id: id).first.value
  end

  def append_or_refresh_quotation(date, value)
    c = quotations.where(date: date).first_or_create
    c.value = Amount.new(value, currency, date)
    c.save!
  end
end
