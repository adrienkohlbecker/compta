class AddEurHistory < ActiveRecord::Migration
  def up
    execute %(CREATE OR REPLACE VIEW view_portfolio_euro_fund_history_eur AS
    SELECT date(date_series.date_series) AS date,
       euro_funds.id AS fund_id,
       'EuroFund'::character varying AS fund_type,
       portfolios.id AS portfolio_id,
       NULL::numeric(15,5) AS shares,
       invested.invested::numeric(15,5) AS invested_original,
       'EUR'::character varying AS invested_currency,
       date(date_series.date_series) AS invested_date,
       (invested.invested + COALESCE(actual_pv.actual_pv, 0::numeric) + COALESCE(latent_pv_this_year.latent_pv_this_year, 0::numeric) + COALESCE(latent_pv_last_year.latent_pv_last_year, 0::numeric))::numeric(15,5) AS current_value_original,
       'EUR'::character varying AS current_value_currency,
       date(date_series.date_series) AS current_value_date,
       NULL::numeric(15,5) AS shareprice_original,
       NULL::character varying AS shareprice_currency,
       NULL::date AS shareprice_date
      FROM generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
              FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series(date_series)
        CROSS JOIN euro_funds
        CROSS JOIN portfolios
        LEFT JOIN LATERAL ( SELECT matview_euro_fund_interest_filled.rate_for_computation,
               matview_euro_fund_interest_filled.year_length
              FROM matview_euro_fund_interest_filled
             WHERE matview_euro_fund_interest_filled.euro_fund_id = euro_funds.id AND matview_euro_fund_interest_filled.date = date(date_series.date_series)) interest_rate ON true
        LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
              FROM matview_portfolio_transactions_with_investment_eur
             WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type::text = 'EuroFund'::text AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id AND matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)) invested ON true
        LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.amount_original) AS actual_pv
              FROM matview_portfolio_transactions_with_investment_eur
             WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type::text = 'EuroFund'::text AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id AND matview_portfolio_transactions_with_investment_eur.done_at < date(date_series.date_series) AND matview_portfolio_transactions_with_investment_eur.category::text <> 'Virement'::text AND matview_portfolio_transactions_with_investment_eur.category::text <> 'Arbitrage'::text) actual_pv ON true
        LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.amount_original * (((1::numeric + interest_rate.rate_for_computation) ^ ((date(date_series.date_series) - matview_portfolio_transactions_with_investment_eur.done_at)::numeric / interest_rate.year_length::numeric)) - 1::numeric)) AS latent_pv_this_year
              FROM matview_portfolio_transactions_with_investment_eur
             WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type::text = 'EuroFund'::text AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id AND matview_portfolio_transactions_with_investment_eur.done_at >= date_trunc('year'::text, date(date_series.date_series)::timestamp with time zone)::date AND matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)) latent_pv_this_year ON true
        LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.amount_original) * (((1::numeric + interest_rate.rate_for_computation) ^ ((date(date_series.date_series) - date_trunc('year'::text, date(date_series.date_series)::timestamp with time zone)::date + 1)::numeric / interest_rate.year_length::numeric)) - 1::numeric) AS latent_pv_last_year
              FROM matview_portfolio_transactions_with_investment_eur
             WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type::text = 'EuroFund'::text AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id AND matview_portfolio_transactions_with_investment_eur.done_at < date_trunc('year'::text, date(date_series.date_series)::timestamp with time zone)::date) latent_pv_last_year ON true
        WHERE invested.invested IS NOT NULL
        ORDER BY date, portfolio_id, fund_id
    )
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_history'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_performance'
  end
  def down
    execute %(
      CREATE OR REPLACE VIEW view_portfolio_euro_fund_history_eur AS
      SELECT date(date_series.date_series) AS date,
         euro_funds.id AS fund_id,
         'EuroFund'::character varying AS fund_type,
         portfolios.id AS portfolio_id,
         NULL::numeric(15,5) AS shares,
         invested.invested::numeric(15,5) AS invested_original,
         NULL::character varying AS invested_currency,
         NULL::date AS invested_date,
         (((invested.invested + COALESCE(actual_pv.actual_pv, (0)::numeric)) + COALESCE(latent_pv_this_year.latent_pv_this_year, (0)::numeric)) + COALESCE(latent_pv_last_year.latent_pv_last_year, (0)::numeric))::numeric(15,5) AS current_value_original,
         NULL::character varying AS current_value_currency,
         NULL::date AS current_value_date,
         NULL::numeric(15,5) AS shareprice_original,
         NULL::character varying AS shareprice_currency,
         NULL::date AS shareprice_date
        FROM (((((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
                FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
          CROSS JOIN euro_funds)
          CROSS JOIN portfolios)
          LEFT JOIN LATERAL ( SELECT matview_euro_fund_interest_filled.rate_for_computation,
                 matview_euro_fund_interest_filled.year_length
                FROM matview_euro_fund_interest_filled
               WHERE ((matview_euro_fund_interest_filled.euro_fund_id = euro_funds.id) AND (matview_euro_fund_interest_filled.date = date(date_series.date_series)))) interest_rate ON (true))
          LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
                FROM matview_portfolio_transactions_with_investment_eur
               WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))) invested ON (true))
          LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.amount_original) AS actual_pv
                FROM matview_portfolio_transactions_with_investment_eur
               WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at < date(date_series.date_series)) AND ((matview_portfolio_transactions_with_investment_eur.category)::text <> 'Virement'::text) AND ((matview_portfolio_transactions_with_investment_eur.category)::text <> 'Arbitrage'::text))) actual_pv ON (true))
          LEFT JOIN LATERAL ( SELECT sum((matview_portfolio_transactions_with_investment_eur.amount_original * ((((1)::numeric + interest_rate.rate_for_computation) ^ (((date(date_series.date_series) - matview_portfolio_transactions_with_investment_eur.done_at))::numeric / (interest_rate.year_length)::numeric)) - (1)::numeric))) AS latent_pv_this_year
                FROM matview_portfolio_transactions_with_investment_eur
               WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at >= (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))) latent_pv_this_year ON (true))
          LEFT JOIN LATERAL ( SELECT (sum(matview_portfolio_transactions_with_investment_eur.amount_original) * ((((1)::numeric + interest_rate.rate_for_computation) ^ ((((date(date_series.date_series) - (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date) + 1))::numeric / (interest_rate.year_length)::numeric)) - (1)::numeric)) AS latent_pv_last_year
                FROM matview_portfolio_transactions_with_investment_eur
               WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at < (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date))) latent_pv_last_year ON (true));
    )
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_history'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_performance'
  end
end
