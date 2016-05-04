class CreateMatviewPortfolioTransactionsEurs < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_portfolio_transactions_eur AS (
      SELECT portfolio_transactions.id, portfolio_transactions.fund_id, portfolio_transactions.shares, portfolio_transactions.portfolio_id, portfolio_transactions.done_at, portfolio_transactions.fund_type, portfolio_transactions.category,
             CASE WHEN portfolio_transactions.amount_currency = 'EUR' THEN portfolio_transactions.amount_original
                  ELSE portfolio_transactions.amount_original / matview_eur_to_currency_for_amount.value
             END AS amount_original,
             'EUR'::character varying AS amount_currency,
             portfolio_transactions.amount_date,
             CASE WHEN portfolio_transactions.shareprice_currency = 'EUR' THEN portfolio_transactions.shareprice_original
                  ELSE portfolio_transactions.shareprice_original / matview_eur_to_currency_for_shareprice.value
             END AS shareprice_original,
             'EUR'::character varying AS shareprice_currency,
             portfolio_transactions.shareprice_date
      FROM portfolio_transactions
      LEFT OUTER JOIN matview_eur_to_currency AS matview_eur_to_currency_for_amount ON portfolio_transactions.amount_date = matview_eur_to_currency_for_amount.date AND portfolio_transactions.amount_currency = matview_eur_to_currency_for_amount.currency_name
      LEFT OUTER JOIN matview_eur_to_currency AS matview_eur_to_currency_for_shareprice ON portfolio_transactions.amount_date = matview_eur_to_currency_for_shareprice.date AND portfolio_transactions.amount_currency = matview_eur_to_currency_for_shareprice.currency_name
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_portfolio_transactions_eur'
  end
end
