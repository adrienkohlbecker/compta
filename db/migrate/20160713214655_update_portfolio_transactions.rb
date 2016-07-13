class UpdatePortfolioTransactions < ActiveRecord::Migration
  def up
    execute %(
    CREATE OR REPLACE VIEW public.view_portfolio_transactions_with_investment AS
      SELECT portfolio_transactions.id,
        portfolio_transactions.fund_id,
        portfolio_transactions.shares,
        portfolio_transactions.portfolio_id,
        portfolio_transactions.done_at,
        portfolio_transactions.fund_type,
        portfolio_transactions.category,
        portfolio_transactions.amount_original,
        portfolio_transactions.amount_currency,
        portfolio_transactions.amount_date,
        portfolio_transactions.shareprice_original,
        portfolio_transactions.shareprice_currency,
        portfolio_transactions.shareprice_date,
            CASE
                WHEN portfolio_transactions.category::text = 'Virement'::text OR portfolio_transactions.category::text = 'Arbitrage'::text THEN portfolio_transactions.amount_original
                ELSE 0::numeric
            END::numeric(15,5) AS invested_original,
        portfolio_transactions.amount_currency AS invested_currency,
        portfolio_transactions.amount_date AS invested_date
       FROM portfolio_transactions
      ORDER BY portfolio_transactions.done_at, portfolio_transactions.portfolio_id, portfolio_transactions.fund_type, portfolio_transactions.fund_id;
    )
    execute %(
    CREATE OR REPLACE VIEW public.view_portfolio_transactions_with_investment_eur AS
       SELECT view_portfolio_transactions_with_investment.id,
          view_portfolio_transactions_with_investment.fund_id,
          view_portfolio_transactions_with_investment.shares,
          view_portfolio_transactions_with_investment.portfolio_id,
          view_portfolio_transactions_with_investment.done_at,
          view_portfolio_transactions_with_investment.fund_type,
          view_portfolio_transactions_with_investment.category,
              CASE
                  WHEN view_portfolio_transactions_with_investment.amount_currency::text = 'EUR'::text THEN view_portfolio_transactions_with_investment.amount_original
                  ELSE view_portfolio_transactions_with_investment.amount_original / matview_eur_to_currency_for_amount.value
              END::numeric(15,5) AS amount_original,
          'EUR'::character varying AS amount_currency,
          view_portfolio_transactions_with_investment.amount_date,
              CASE
                  WHEN view_portfolio_transactions_with_investment.shareprice_currency::text = 'EUR'::text THEN view_portfolio_transactions_with_investment.shareprice_original
                  ELSE view_portfolio_transactions_with_investment.shareprice_original / matview_eur_to_currency_for_shareprice.value
              END::numeric(15,5) AS shareprice_original,
          'EUR'::character varying AS shareprice_currency,
          view_portfolio_transactions_with_investment.shareprice_date,
              CASE
                  WHEN view_portfolio_transactions_with_investment.invested_currency::text = 'EUR'::text THEN view_portfolio_transactions_with_investment.invested_original
                  ELSE view_portfolio_transactions_with_investment.invested_original / matview_eur_to_currency_for_amount.value
              END::numeric(15,5) AS invested_original,
          'EUR'::character varying AS invested_currency,
          view_portfolio_transactions_with_investment.invested_date
         FROM view_portfolio_transactions_with_investment
           LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_amount ON view_portfolio_transactions_with_investment.amount_date = matview_eur_to_currency_for_amount.date AND view_portfolio_transactions_with_investment.amount_currency::text = matview_eur_to_currency_for_amount.currency_name::text
           LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_shareprice ON view_portfolio_transactions_with_investment.amount_date = matview_eur_to_currency_for_shareprice.date AND view_portfolio_transactions_with_investment.amount_currency::text = matview_eur_to_currency_for_shareprice.currency_name::text
           LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_invested ON view_portfolio_transactions_with_investment.amount_date = matview_eur_to_currency_for_invested.date AND view_portfolio_transactions_with_investment.amount_currency::text = matview_eur_to_currency_for_invested.currency_name::text
        ORDER BY view_portfolio_transactions_with_investment.done_at, view_portfolio_transactions_with_investment.portfolio_id, view_portfolio_transactions_with_investment.fund_type, view_portfolio_transactions_with_investment.fund_id;

    )
    execute 'DROP MATERIALIZED VIEW matview_portfolio_transactions_eur'
    execute 'DROP VIEW view_portfolio_transactions_eur'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur'
  end
  def down
    execute %(
    CREATE OR REPLACE VIEW public.view_portfolio_transactions_eur AS
     SELECT portfolio_transactions.id,
        portfolio_transactions.fund_id,
        portfolio_transactions.shares,
        portfolio_transactions.portfolio_id,
        portfolio_transactions.done_at,
        portfolio_transactions.fund_type,
        portfolio_transactions.category,
            CASE
                WHEN portfolio_transactions.amount_currency::text = 'EUR'::text THEN portfolio_transactions.amount_original
                ELSE portfolio_transactions.amount_original / matview_eur_to_currency_for_amount.value
            END::numeric(15,5) AS amount_original,
        'EUR'::character varying AS amount_currency,
        portfolio_transactions.amount_date,
            CASE
                WHEN portfolio_transactions.shareprice_currency::text = 'EUR'::text THEN portfolio_transactions.shareprice_original
                ELSE portfolio_transactions.shareprice_original / matview_eur_to_currency_for_shareprice.value
            END::numeric(15,5) AS shareprice_original,
        'EUR'::character varying AS shareprice_currency,
        portfolio_transactions.shareprice_date
       FROM portfolio_transactions
         LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_amount ON portfolio_transactions.amount_date = matview_eur_to_currency_for_amount.date AND portfolio_transactions.amount_currency::text = matview_eur_to_currency_for_amount.currency_name::text
         LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_shareprice ON portfolio_transactions.amount_date = matview_eur_to_currency_for_shareprice.date AND portfolio_transactions.amount_currency::text = matview_eur_to_currency_for_shareprice.currency_name::text
      ORDER BY portfolio_transactions.done_at, portfolio_transactions.portfolio_id, portfolio_transactions.fund_type, portfolio_transactions.fund_id;
    )
    execute %(
    CREATE MATERIALIZED VIEW public.matview_portfolio_transactions_eur AS
     SELECT view_portfolio_transactions_eur.id,
        view_portfolio_transactions_eur.fund_id,
        view_portfolio_transactions_eur.shares,
        view_portfolio_transactions_eur.portfolio_id,
        view_portfolio_transactions_eur.done_at,
        view_portfolio_transactions_eur.fund_type,
        view_portfolio_transactions_eur.category,
        view_portfolio_transactions_eur.amount_original,
        view_portfolio_transactions_eur.amount_currency,
        view_portfolio_transactions_eur.amount_date,
        view_portfolio_transactions_eur.shareprice_original,
        view_portfolio_transactions_eur.shareprice_currency,
        view_portfolio_transactions_eur.shareprice_date
       FROM view_portfolio_transactions_eur
    )
    execute %(
    CREATE OR REPLACE VIEW public.view_portfolio_transactions_with_investment_eur AS
      SELECT matview_portfolio_transactions_eur.id,
         matview_portfolio_transactions_eur.fund_id,
         matview_portfolio_transactions_eur.shares,
         matview_portfolio_transactions_eur.portfolio_id,
         matview_portfolio_transactions_eur.done_at,
         matview_portfolio_transactions_eur.fund_type,
         matview_portfolio_transactions_eur.category,
         matview_portfolio_transactions_eur.amount_original,
         matview_portfolio_transactions_eur.amount_currency,
         matview_portfolio_transactions_eur.amount_date,
         matview_portfolio_transactions_eur.shareprice_original,
         matview_portfolio_transactions_eur.shareprice_currency,
         matview_portfolio_transactions_eur.shareprice_date,
             CASE
                 WHEN matview_portfolio_transactions_eur.category::text = 'Virement'::text OR matview_portfolio_transactions_eur.category::text = 'Arbitrage'::text THEN matview_portfolio_transactions_eur.amount_original
                 ELSE 0::numeric
             END::numeric(15,5) AS invested_original,
         matview_portfolio_transactions_eur.amount_currency AS invested_currency,
         matview_portfolio_transactions_eur.amount_date AS invested_date
        FROM matview_portfolio_transactions_eur
       ORDER BY matview_portfolio_transactions_eur.done_at, matview_portfolio_transactions_eur.portfolio_id, matview_portfolio_transactions_eur.fund_type, matview_portfolio_transactions_eur.fund_id;

    )
    execute 'DROP VIEW view_portfolio_transactions_with_investment'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur'
  end
end
