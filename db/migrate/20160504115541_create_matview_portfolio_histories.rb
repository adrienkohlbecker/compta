# frozen_string_literal: true
class CreateMatviewPortfolioHistories < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_portfolio_history AS (
      SELECT history.date, history.fund_id, history.fund_type, history.portfolio_id,
             CASE WHEN abs(history.shares) < 0.001 THEN NULL ELSE history.shares END AS shares,
             history.invested,
             CASE WHEN abs(history.shares) < 0.001 THEN NULL ELSE history.current_value END AS current_value,
             CASE WHEN abs(history.shares) < 0.001 THEN - history.invested ELSE history.current_value - history.invested END AS pv,
             CASE WHEN abs(history.shares) < 0.001 THEN NULL ELSE (history.current_value / history.invested - 1) END AS percent
      FROM (SELECT * FROM matview_portfolio_euro_fund_history_eur UNION SELECT * FROM matview_portfolio_opcvm_fund_history_eur) AS history
      ORDER BY history.date, history.portfolio_id, history.fund_type, history.fund_id
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_portfolio_history'
  end
end
