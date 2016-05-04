class CreateMatviewPortfolioPerformances < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_portfolio_performance AS (
        SELECT date, portfolio_id, SUM(invested) AS invested, SUM(current_value) AS current_value, SUM(pv) AS pv FROM matview_portfolio_history
        GROUP BY date, portfolio_id ORDER BY date, portfolio_id ASC
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_portfolio_performance'
  end
end
