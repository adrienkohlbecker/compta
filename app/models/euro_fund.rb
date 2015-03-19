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
end
