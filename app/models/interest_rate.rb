# == Schema Information
#
# Table name: interest_rates
#
#  id          :integer          not null, primary key
#  object_id   :integer
#  object_type :string
#  rate        :decimal(15, 5)
#  from        :date
#  to          :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class InterestRate < ActiveRecord::Base
  belongs_to :object, polymorphic: true
end
