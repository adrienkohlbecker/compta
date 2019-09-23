# frozen_string_literal: true
class Matview::Base < ActiveRecord::Base
  self.abstract_class = true
  self.pluralize_table_names = false

  def self.refresh_all
    connection.execute 'REFRESH MATERIALIZED VIEW matview_eur_to_currency;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled_eur;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_filled;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_filled_eur;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_euro_fund_interest_filled;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_portfolio_scpi_fund_history_eur;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_portfolio_history;'
    connection.execute 'REFRESH MATERIALIZED VIEW matview_portfolio_performance;'
  end

  def self.table_name_prefix
    'matview_'
  end

  def readonly?
    true
  end

  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end
end
