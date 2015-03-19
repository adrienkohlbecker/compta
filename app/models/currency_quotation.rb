# == Schema Information
#
# Table name: currency_quotations
#
#  id          :integer          not null, primary key
#  currency_id :integer
#  date        :date
#  value       :decimal(15, 5)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class CurrencyQuotation < ActiveRecord::Base
  belongs_to :currency
end
