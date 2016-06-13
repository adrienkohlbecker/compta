# frozen_string_literal: true
class Matview::PortfolioHistory < Matview::Base
  belongs_to :fund, polymorphic: true

  def invested
    @_invested ||= self[:invested].nil? ? nil : Amount.new(self[:invested], 'EUR', date)
  end

  def current_value
    @_current_value ||= self[:current_value].nil? ? nil : Amount.new(self[:current_value], 'EUR', date)
  end

  def pv
    @_pv ||= self[:pv].nil? ? nil : Amount.new(self[:pv], 'EUR', date)
  end
end
