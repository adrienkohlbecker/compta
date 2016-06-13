# frozen_string_literal: true
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

  def self.equivalent_rate(transactions, current_value, lower_bound, upper_bound, max_iter = 30)
    raise 'Maximum iterations reached' if max_iter == 0

    candidate = (lower_bound + upper_bound) / 2.0

    total = 0
    transactions.each do |t|
      days = Date.today - t.done_at
      total += t.amount_original * (1 + candidate)**(days / 365.0)
    end

    delta = total - current_value

    return candidate if delta < 0.001 && delta > - 0.001

    if delta < 0
      return equivalent_rate(transactions, current_value, candidate, upper_bound, max_iter - 1)
    else
      return equivalent_rate(transactions, current_value, lower_bound, candidate, max_iter - 1)
    end
  end
end
