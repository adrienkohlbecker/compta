# frozen_string_literal: true
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
  has_many :quotations, -> { order(date: :desc) }, class_name: 'OpcvmQuotation'
  has_many :quotations_filled_eur, -> { where.not(value_original: nil).order(date: :desc) }, class_name: 'Matview::OpcvmQuotationsFilledEur'
  has_many :transactions, class_name: 'PortfolioTransaction', as: :fund

  def refresh_data
    data = Boursorama::Fund.new(boursorama_id, boursorama_type).export

    self.isin = data[:isin]
    self.name = data[:name]
    self.currency = data[:currency]
    save!
  end

  def refresh_quotation_history
    transaction do
      history = Boursorama::QuotationHistory.new(boursorama_id).quotation_history

      history.each do |date, value|
        append_or_refresh_quotation(date, value)
      end
    end

    nil
  end

  def quotation_at(date)
    Matview::OpcvmQuotationsFilledEur.where(date: date, opcvm_fund_id: id).first.value
  end

  def append_or_refresh_quotation(date, value)
    c = quotations.where(date: date).first_or_create
    c.value = value.nil? ? nil : Amount.new(value, currency, date)
    c.save!
  end

  def gnucash_commodity
    GnuCash::Commodity.where(cusip: isin).first
  end
end
