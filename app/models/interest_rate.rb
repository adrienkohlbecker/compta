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

  def self.equivalent_rate(transactions, current_value, lower_bound, upper_bound, max_iter = 300)
    raise 'Maximum iterations reached' if max_iter == 0

    candidate = (lower_bound + upper_bound) / 2.0
    total = compute_interest(transactions, candidate)
    delta = total - current_value

    return candidate if delta < 0.001 && delta > - 0.001

    if delta < 0
      return equivalent_rate(transactions, current_value, candidate, upper_bound, max_iter - 1)
    else
      return equivalent_rate(transactions, current_value, lower_bound, candidate, max_iter - 1)
    end
  end

  def self.compute_interest(transactions, rate)
    amount_by_day = transactions.group_by(&:done_at).map { |date, ts| { date: date, value: ts.map(&:amount_original).reduce(:+) } }
    amount_by_day = amount_by_day.sort_by { |h| h[:date] }

    running_total = 0
    dates_per_amount = []
    (1..amount_by_day.length).each do |i|
      from = amount_by_day[i - 1][:date]
      to = (i == amount_by_day.length) ? Date.today : amount_by_day[i][:date]
      amount = running_total + amount_by_day[i - 1][:value]
      running_total += amount_by_day[i - 1][:value]

      dates_per_amount << { from: from, to: to, amount: amount }
    end

    days_per_amount = []
    dates_per_amount.each do |h|
      from = h[:from]
      to = h[:to]

      (from.year..to.year).each do |y|
        from = (h[:from].year == y) ? h[:from] : from.beginning_of_year
        to = (h[:to].year == y) ? h[:to] : from.end_of_year + 1
        year_length = 1 + (Date.new(y, 1, 1).end_of_year - Date.new(y, 1, 1))

        days_per_amount << { days: to - from, amount: h[:amount], year_length: year_length }

        from = to
      end
    end

    total_pv = 0
    last = 0
    days_per_amount.each do |h|
      last = (last + h[:amount]).to_f * ((1 + rate.to_f)**(h[:days].to_f / h[:year_length].to_f))
    end

    last
  end
end
