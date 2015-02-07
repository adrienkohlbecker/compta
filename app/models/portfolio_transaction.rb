class PortfolioTransaction < ActiveRecord::Base
  belongs_to :fund
  belongs_to :portfolio
end
