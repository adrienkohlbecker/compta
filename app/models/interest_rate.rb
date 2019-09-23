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

  def self.equivalent_rate(transactions, current_value, lower_bound, upper_bound, current_date, max_iter = 300)
    raise 'Maximum iterations reached' if max_iter == 0

    candidate = (lower_bound + upper_bound) / 2.0
    total = compute_interest(transactions, candidate, current_date)
    delta = total - current_value

    return candidate if delta < 0.001 && delta > - 0.001

    if delta < 0
      return equivalent_rate(transactions, current_value, candidate, upper_bound, current_date, max_iter - 1)
    else
      return equivalent_rate(transactions, current_value, lower_bound, candidate, current_date, max_iter - 1)
    end
  end

  def self.compute_interest(transactions, rate, current_date)
    amount_by_day = transactions.group_by(&:done_at).map { |date, ts| { date: date, value: ts.map(&:amount_original).reduce(:+) } }
    amount_by_day = amount_by_day.sort_by { |h| h[:date] }

    dates_per_amount = []
    days_per_amount = []
    last = 0
    (1..amount_by_day.length).each do |i|
      from = amount_by_day[i - 1][:date]
      to = (i == amount_by_day.length) ? current_date : amount_by_day[i][:date]
      amount = amount_by_day[i - 1][:value]

      last += amount

      (from.year..to.year).each do |y|
        from = (from.year == y) ? from : from.beginning_of_year
        to = (to.year == y) ? to : from.end_of_year + 1
        year_length = 1 + (Date.new(y, 1, 1).end_of_year - Date.new(y, 1, 1))

        last = (last).to_f * ((1 + rate.to_f)**((to - from).to_f / year_length.to_f))

        from = to
      end
    end

    last
  end
end
