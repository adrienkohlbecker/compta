# frozen_string_literal: true
class Matview::PortfolioPerformance < Matview::Base
  def invested
    @_invested ||= self[:invested_original].nil? ? nil : Amount.new(self[:invested_original], self[:invested_currency], self[:invested_date])
  end

  def current_value
    @_current_value ||= self[:current_value_original].nil? ? nil : Amount.new(self[:current_value_original], self[:current_value_currency], self[:current_value_date])
  end

  def pv
    @_pv ||= self[:pv_original].nil? ? nil : Amount.new(self[:pv_original], self[:pv_currency], self[:pv_date])
  end
end
