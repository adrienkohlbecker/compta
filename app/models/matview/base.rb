class Matview::Base < ActiveRecord::Base
  self.abstract_class = true
  self.pluralize_table_names = false

  def self.refresh_all
    connection.execute %(
      REFRESH MATERIALIZED VIEW matview_eur_to_currency;
      REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled;
      REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled_eur;
      REFRESH MATERIALIZED VIEW matview_portfolio_transactions_eur;
      REFRESH MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur;
      REFRESH MATERIALIZED VIEW matview_euro_fund_interest_filled;
      REFRESH MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur;
      REFRESH MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur;
      REFRESH MATERIALIZED VIEW matview_portfolio_history;
      REFRESH MATERIALIZED VIEW matview_portfolio_performance;
    )
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
