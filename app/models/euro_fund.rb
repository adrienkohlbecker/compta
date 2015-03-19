class EuroFund < ActiveRecord::Base
  has_many :euro_fund_investments
  has_many :quotations, class_name: 'FundQuotation', as: :fund
  has_many :transactions, class_name: 'PortfolioTransaction', as: :fund

  def quotation_at(date)
    quotations.order("date DESC").where("date <= ?", date).first.value
  end

  def append_or_refresh_quotation(date, value)
    c = quotations.where(date: date).first_or_create
    c.value = Amount.new(value, currency, date)
    c.save!
  end

end
