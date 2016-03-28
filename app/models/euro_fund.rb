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
    object = interest_rates.where('"from" <= ?', date).where('"to" > ?', date).first
    (object.served_rate || object.minimal_rate) * (1 - object.social_tax_rate)
  end
end
