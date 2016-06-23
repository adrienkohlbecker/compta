class ScpiFund < ActiveRecord::Base
  has_many :quotations, class_name: 'OpcvmQuotation'
  has_many :transactions, class_name: 'PortfolioTransaction', as: :fund

  def quotation_at(date)
    Matview::OpcvmQuotationsFilled.where(date: date, opcvm_fund_id: id).first.value
  end

  def append_or_refresh_quotation(date, value)
    c = quotations.where(date: date).first_or_create
    c.value = Amount.new(value, currency, date)
    c.save!
  end

  def gnucash_commodity
    GnuCash::Commodity.where(cusip: name).first
  end
end
