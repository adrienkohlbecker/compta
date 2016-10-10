# frozen_string_literal: true
# == Schema Information
#
# Table name: portfolios
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Portfolio < ActiveRecord::Base
  has_many :transactions, class_name: 'PortfolioTransaction'
  has_many :euro_fund_investments

  def currency
    'EUR'
  end

  def invested_at(date)
    transactions.where(category: PortfolioTransaction::CATEGORY_FOR_INVESTED).where('done_at <= ?', date).map { |t| t.amount.to_eur }.reduce(:+) || 0
  end
end
