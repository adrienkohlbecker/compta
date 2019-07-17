class ScpiFund < ActiveRecord::Base
  has_many :quotations, -> { order(date: :desc) }, class_name: 'ScpiQuotation'
  has_many :quotations_filled_eur, -> { where.not(value_original: nil).order(date: :desc) }, class_name: 'Matview::ScpiQuotationsFilledEur'
  has_many :transactions, class_name: 'PortfolioTransaction', as: :fund

  def quotation_at(date)
    Matview::ScpiQuotationsFilledEur.where(date: date, scpi_fund_id: id).first.value
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
