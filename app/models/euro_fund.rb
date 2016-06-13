# frozen_string_literal: true
# == Schema Information
#
# Table name: euro_funds
#
#  id         :integer          not null, primary key
#  name       :string
#  currency   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class EuroFund < ActiveRecord::Base
  has_many :transactions, class_name: 'PortfolioTransaction', as: :fund
  has_many :interest_rates, as: :object

  def current_interest_rate(date = Date.today)
    Matview::EuroFundInterestFilled.where(date: date, euro_fund_id: id).first.rate_for_computation
  end
end
