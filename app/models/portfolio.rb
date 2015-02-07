class Portfolio < ActiveRecord::Base
  has_many :transactions, class_name: 'PortfolioTransaction'
end
