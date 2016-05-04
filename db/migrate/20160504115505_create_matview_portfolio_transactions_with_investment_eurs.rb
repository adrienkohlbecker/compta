class CreateMatviewPortfolioTransactionsWithInvestmentEurs < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur AS (
      SELECT matview_portfolio_transactions_eur.*,
      	CASE WHEN category = 'Virement' OR category = 'Arbitrage' THEN matview_portfolio_transactions_eur.amount_original
      	     ELSE 0
      	END AS invested_original,
      	matview_portfolio_transactions_eur.amount_currency AS invested_currency,
      	matview_portfolio_transactions_eur.amount_date AS invested_date
      FROM matview_portfolio_transactions_eur
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur'
  end
end
