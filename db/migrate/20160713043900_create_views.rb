# frozen_string_literal: true
class CreateViews < ActiveRecord::Migration
  def up
    execute %(
      DROP MATERIALIZED VIEW matview_portfolio_performance;
      DROP MATERIALIZED VIEW matview_portfolio_history;
      DROP MATERIALIZED VIEW matview_portfolio_scpi_fund_history_eur;
      DROP MATERIALIZED VIEW matview_scpi_quotations_filled_eur;
      DROP MATERIALIZED VIEW matview_scpi_quotations_filled;
      DROP MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur;
      DROP MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur;
      DROP MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur;
      DROP MATERIALIZED VIEW matview_portfolio_transactions_eur;
      DROP MATERIALIZED VIEW matview_opcvm_quotations_filled_eur;
      DROP MATERIALIZED VIEW matview_opcvm_quotations_filled;
      DROP MATERIALIZED VIEW matview_euro_fund_interest_filled;
      DROP MATERIALIZED VIEW matview_eur_to_currency;

      CREATE VIEW view_eur_to_currency AS
       SELECT currencies.id AS currency_id,
          currencies.name AS currency_name,
          date(date_series.date_series) AS date,
          t.value
         FROM ((generate_series((( SELECT min(currency_quotations.date) AS min
                 FROM currency_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN currencies)
           LEFT JOIN LATERAL ( SELECT currency_quotations.id,
                  currency_quotations.currency_id,
                  currency_quotations.date,
                  currency_quotations.value,
                  currency_quotations.created_at,
                  currency_quotations.updated_at
                 FROM currency_quotations
                WHERE ((currency_quotations.date <= date_series.date_series) AND (currency_quotations.currency_id = currencies.id))
                ORDER BY currency_quotations.date DESC
               LIMIT 1) t ON (true));

      CREATE MATERIALIZED VIEW matview_eur_to_currency AS SELECT * FROM view_eur_to_currency;

      CREATE VIEW view_euro_fund_interest_filled AS
       SELECT euro_funds.id AS euro_fund_id,
          date(date_series.date_series) AS date,
          t.minimal_rate,
          t.served_rate,
          t.year_length,
          (COALESCE(t.served_rate, t.minimal_rate) * ((1)::numeric - t.social_tax_rate))::numeric(15,5) AS rate_for_computation
         FROM ((generate_series((( SELECT min(interest_rates."from") AS min
                 FROM interest_rates))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN euro_funds)
           LEFT JOIN LATERAL ( SELECT interest_rates.id,
                  interest_rates.object_id,
                  interest_rates.object_type,
                  interest_rates.minimal_rate,
                  interest_rates."from",
                  interest_rates."to",
                  interest_rates.created_at,
                  interest_rates.updated_at,
                  interest_rates.served_rate,
                  interest_rates.social_tax_rate,
                  interest_rates.year_length
                 FROM interest_rates
                WHERE ((interest_rates."from" <= date_series.date_series) AND (interest_rates.object_id = euro_funds.id) AND ((interest_rates.object_type)::text = 'EuroFund'::text))
                ORDER BY interest_rates."to" DESC
               LIMIT 1) t ON (true));

      CREATE MATERIALIZED VIEW matview_euro_fund_interest_filled AS SELECT * FROM view_euro_fund_interest_filled;

      CREATE VIEW view_opcvm_quotations_filled AS
       SELECT opcvm_funds.id AS opcvm_fund_id,
          date(date_series.date_series) AS date,
          t.value_original,
          t.value_currency,
          t.value_date
         FROM ((generate_series((( SELECT min(opcvm_quotations.date) AS min
                 FROM opcvm_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN opcvm_funds)
           JOIN LATERAL ( SELECT opcvm_quotations.id,
                  opcvm_quotations.opcvm_fund_id,
                  opcvm_quotations.value_original,
                  opcvm_quotations.date,
                  opcvm_quotations.created_at,
                  opcvm_quotations.updated_at,
                  opcvm_quotations.value_currency,
                  opcvm_quotations.value_date
                 FROM opcvm_quotations
                WHERE ((opcvm_quotations.date <= date_series.date_series) AND (opcvm_quotations.opcvm_fund_id = opcvm_funds.id))
                ORDER BY opcvm_quotations.date DESC
               LIMIT 1) t ON (true));

      CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled AS SELECT * FROM view_opcvm_quotations_filled;

      CREATE VIEW view_opcvm_quotations_filled_eur AS
       SELECT matview_opcvm_quotations_filled.opcvm_fund_id,
          matview_opcvm_quotations_filled.date,
              CASE
                  WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_opcvm_quotations_filled.value_original
                  ELSE (matview_opcvm_quotations_filled.value_original / matview_eur_to_currency.value)
              END AS value_original,
          'EUR'::character varying AS value_currency,
          matview_opcvm_quotations_filled.value_date
         FROM (matview_opcvm_quotations_filled
           LEFT JOIN matview_eur_to_currency ON (((matview_opcvm_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_opcvm_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))));

      CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled_eur AS SELECT * FROM view_opcvm_quotations_filled_eur;

      CREATE VIEW view_portfolio_transactions_eur AS
       SELECT portfolio_transactions.id,
          portfolio_transactions.fund_id,
          portfolio_transactions.shares,
          portfolio_transactions.portfolio_id,
          portfolio_transactions.done_at,
          portfolio_transactions.fund_type,
          portfolio_transactions.category,
              CASE
                  WHEN ((portfolio_transactions.amount_currency)::text = 'EUR'::text) THEN portfolio_transactions.amount_original
                  ELSE (portfolio_transactions.amount_original / matview_eur_to_currency_for_amount.value)
              END AS amount_original,
          'EUR'::character varying AS amount_currency,
          portfolio_transactions.amount_date,
              CASE
                  WHEN ((portfolio_transactions.shareprice_currency)::text = 'EUR'::text) THEN portfolio_transactions.shareprice_original
                  ELSE (portfolio_transactions.shareprice_original / matview_eur_to_currency_for_shareprice.value)
              END AS shareprice_original,
          'EUR'::character varying AS shareprice_currency,
          portfolio_transactions.shareprice_date
         FROM ((portfolio_transactions
           LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_amount ON (((portfolio_transactions.amount_date = matview_eur_to_currency_for_amount.date) AND ((portfolio_transactions.amount_currency)::text = (matview_eur_to_currency_for_amount.currency_name)::text))))
           LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_shareprice ON (((portfolio_transactions.amount_date = matview_eur_to_currency_for_shareprice.date) AND ((portfolio_transactions.amount_currency)::text = (matview_eur_to_currency_for_shareprice.currency_name)::text))));

      CREATE MATERIALIZED VIEW matview_portfolio_transactions_eur AS SELECT * FROM view_portfolio_transactions_eur;

      CREATE VIEW view_portfolio_transactions_with_investment_eur AS
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
                  WHEN (((matview_portfolio_transactions_eur.category)::text = 'Virement'::text) OR ((matview_portfolio_transactions_eur.category)::text = 'Arbitrage'::text)) THEN matview_portfolio_transactions_eur.amount_original
                  ELSE (0)::numeric
              END AS invested_original,
          matview_portfolio_transactions_eur.amount_currency AS invested_currency,
          matview_portfolio_transactions_eur.amount_date AS invested_date
         FROM matview_portfolio_transactions_eur;

      CREATE MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur AS SELECT * FROM view_portfolio_transactions_with_investment_eur;

      CREATE VIEW view_portfolio_euro_fund_history_eur AS
       SELECT date(date_series.date_series) AS date,
          euro_funds.id AS fund_id,
          'EuroFund'::character varying AS fund_type,
          portfolios.id AS portfolio_id,
          NULL::numeric(15,5) AS shares,
          invested.invested,
          (((invested.invested + COALESCE(actual_pv.actual_pv, (0)::numeric)) + COALESCE(latent_pv_this_year.latent_pv_this_year, (0)::numeric)) + COALESCE(latent_pv_last_year.latent_pv_last_year, (0)::numeric)) AS current_value
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

      CREATE MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur AS SELECT * FROM view_portfolio_euro_fund_history_eur;

      CREATE VIEW view_portfolio_opcvm_fund_history_eur AS
       SELECT date(date_series.date_series) AS date,
          opcvm_funds.id AS fund_id,
          'OpcvmFund'::character varying AS fund_type,
          portfolios.id AS portfolio_id,
          t.shares,
          t.invested,
          (matview_opcvm_quotations_filled_eur.value_original * t.shares) AS current_value
         FROM ((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
                 FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN opcvm_funds)
           CROSS JOIN portfolios)
           LEFT JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
                  matview_portfolio_transactions_with_investment_eur.portfolio_id,
                  sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
                  sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
                 FROM matview_portfolio_transactions_with_investment_eur
                WHERE (((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'OpcvmFund'::text) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))
                GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON (((t.fund_id = opcvm_funds.id) AND (t.portfolio_id = portfolios.id))))
           JOIN matview_opcvm_quotations_filled_eur ON (((opcvm_funds.id = matview_opcvm_quotations_filled_eur.opcvm_fund_id) AND (matview_opcvm_quotations_filled_eur.date = date(date_series.date_series)))));

      CREATE MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur AS SELECT * FROM view_portfolio_opcvm_fund_history_eur;

      CREATE VIEW view_scpi_quotations_filled AS
       SELECT scpi_funds.id AS scpi_fund_id,
          date(date_series.date_series) AS date,
          t.value_original,
          t.value_currency,
          t.value_date
         FROM ((generate_series((( SELECT min(scpi_quotations.date) AS min
                 FROM scpi_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN scpi_funds)
           JOIN LATERAL ( SELECT scpi_quotations.id,
                  scpi_quotations.value_original,
                  scpi_quotations.value_currency,
                  scpi_quotations.value_date,
                  scpi_quotations.subscription_value_original,
                  scpi_quotations.subscription_value_currency,
                  scpi_quotations.subscription_value_date,
                  scpi_quotations.date,
                  scpi_quotations.scpi_fund_id,
                  scpi_quotations.created_at,
                  scpi_quotations.updated_at
                 FROM scpi_quotations
                WHERE ((scpi_quotations.date <= date_series.date_series) AND (scpi_quotations.scpi_fund_id = scpi_funds.id))
                ORDER BY scpi_quotations.date DESC
               LIMIT 1) t ON (true));

      CREATE MATERIALIZED VIEW matview_scpi_quotations_filled AS SELECT * FROM view_scpi_quotations_filled;

      CREATE VIEW view_scpi_quotations_filled_eur AS
       SELECT matview_scpi_quotations_filled.scpi_fund_id,
          matview_scpi_quotations_filled.date,
              CASE
                  WHEN ((matview_scpi_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_scpi_quotations_filled.value_original
                  ELSE (matview_scpi_quotations_filled.value_original / matview_eur_to_currency.value)
              END AS value_original,
          'EUR'::character varying AS value_currency,
          matview_scpi_quotations_filled.value_date
         FROM (matview_scpi_quotations_filled
           LEFT JOIN matview_eur_to_currency ON (((matview_scpi_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_scpi_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))));

      CREATE MATERIALIZED VIEW matview_scpi_quotations_filled_eur AS SELECT * FROM view_scpi_quotations_filled_eur;

      CREATE VIEW view_portfolio_scpi_fund_history_eur AS
       SELECT date(date_series.date_series) AS date,
          scpi_funds.id AS fund_id,
          'ScpiFund'::character varying AS fund_type,
          portfolios.id AS portfolio_id,
          t.shares,
          t.invested,
          (matview_scpi_quotations_filled_eur.value_original * t.shares) AS current_value
         FROM ((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
                 FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN scpi_funds)
           CROSS JOIN portfolios)
           LEFT JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
                  matview_portfolio_transactions_with_investment_eur.portfolio_id,
                  sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
                  sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
                 FROM matview_portfolio_transactions_with_investment_eur
                WHERE (((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'ScpiFund'::text) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))
                GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON (((t.fund_id = scpi_funds.id) AND (t.portfolio_id = portfolios.id))))
           JOIN matview_scpi_quotations_filled_eur ON (((scpi_funds.id = matview_scpi_quotations_filled_eur.scpi_fund_id) AND (matview_scpi_quotations_filled_eur.date = date(date_series.date_series)))));

      CREATE MATERIALIZED VIEW matview_portfolio_scpi_fund_history_eur AS SELECT * FROM view_portfolio_scpi_fund_history_eur;

      CREATE VIEW view_portfolio_history AS
       SELECT history.date,
          history.fund_id,
          history.fund_type,
          history.portfolio_id,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  ELSE history.shares
              END AS shares,
          history.invested,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  ELSE history.current_value
              END AS current_value,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN (- history.invested)
                  ELSE (history.current_value - history.invested)
              END AS pv,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  WHEN (history.invested = (0)::numeric) THEN NULL::numeric
                  ELSE ((history.current_value / history.invested) - (1)::numeric)
              END AS percent
         FROM ( SELECT matview_portfolio_euro_fund_history_eur.date,
                  matview_portfolio_euro_fund_history_eur.fund_id,
                  matview_portfolio_euro_fund_history_eur.fund_type,
                  matview_portfolio_euro_fund_history_eur.portfolio_id,
                  matview_portfolio_euro_fund_history_eur.shares,
                  matview_portfolio_euro_fund_history_eur.invested,
                  matview_portfolio_euro_fund_history_eur.current_value
                 FROM matview_portfolio_euro_fund_history_eur
              UNION
               SELECT matview_portfolio_opcvm_fund_history_eur.date,
                  matview_portfolio_opcvm_fund_history_eur.fund_id,
                  matview_portfolio_opcvm_fund_history_eur.fund_type,
                  matview_portfolio_opcvm_fund_history_eur.portfolio_id,
                  matview_portfolio_opcvm_fund_history_eur.shares,
                  matview_portfolio_opcvm_fund_history_eur.invested,
                  matview_portfolio_opcvm_fund_history_eur.current_value
                 FROM matview_portfolio_opcvm_fund_history_eur
              UNION
               SELECT matview_portfolio_scpi_fund_history_eur.date,
                  matview_portfolio_scpi_fund_history_eur.fund_id,
                  matview_portfolio_scpi_fund_history_eur.fund_type,
                  matview_portfolio_scpi_fund_history_eur.portfolio_id,
                  matview_portfolio_scpi_fund_history_eur.shares,
                  matview_portfolio_scpi_fund_history_eur.invested,
                  matview_portfolio_scpi_fund_history_eur.current_value
                 FROM matview_portfolio_scpi_fund_history_eur) history
        ORDER BY history.date, history.portfolio_id, history.fund_type, history.fund_id;

      CREATE MATERIALIZED VIEW matview_portfolio_history AS SELECT * FROM view_portfolio_history;

      CREATE VIEW view_portfolio_performance AS
       SELECT matview_portfolio_history.date,
          matview_portfolio_history.portfolio_id,
          sum(matview_portfolio_history.invested) AS invested,
          sum(matview_portfolio_history.current_value) AS current_value,
          sum(matview_portfolio_history.pv) AS pv
         FROM matview_portfolio_history
        GROUP BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id
        ORDER BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id;

      CREATE MATERIALIZED VIEW matview_portfolio_performance AS SELECT * FROM view_portfolio_performance;
    )
  end

  def down
    execute %(
      DROP MATERIALIZED VIEW matview_portfolio_performance;
      DROP VIEW view_portfolio_performance;

      DROP MATERIALIZED VIEW matview_portfolio_history;
      DROP VIEW view_portfolio_history;

      DROP MATERIALIZED VIEW matview_portfolio_scpi_fund_history_eur;
      DROP VIEW view_portfolio_scpi_fund_history_eur;

      DROP MATERIALIZED VIEW matview_scpi_quotations_filled_eur;
      DROP VIEW view_scpi_quotations_filled_eur;

      DROP MATERIALIZED VIEW matview_scpi_quotations_filled;
      DROP VIEW view_scpi_quotations_filled;

      DROP MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur;
      DROP VIEW view_portfolio_opcvm_fund_history_eur;

      DROP MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur;
      DROP VIEW view_portfolio_euro_fund_history_eur;

      DROP MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur;
      DROP VIEW view_portfolio_transactions_with_investment_eur;

      DROP MATERIALIZED VIEW matview_portfolio_transactions_eur;
      DROP VIEW view_portfolio_transactions_eur;

      DROP MATERIALIZED VIEW matview_opcvm_quotations_filled_eur;
      DROP VIEW view_opcvm_quotations_filled_eur;

      DROP MATERIALIZED VIEW matview_opcvm_quotations_filled;
      DROP VIEW view_opcvm_quotations_filled;

      DROP MATERIALIZED VIEW matview_euro_fund_interest_filled;
      DROP VIEW view_euro_fund_interest_filled;

      DROP MATERIALIZED VIEW matview_eur_to_currency;
      DROP VIEW view_eur_to_currency;

      CREATE MATERIALIZED VIEW matview_eur_to_currency AS
       SELECT currencies.id AS currency_id,
          currencies.name AS currency_name,
          date(date_series.date_series) AS date,
          t.value
         FROM ((generate_series((( SELECT min(currency_quotations.date) AS min
                 FROM currency_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN currencies)
           LEFT JOIN LATERAL ( SELECT currency_quotations.id,
                  currency_quotations.currency_id,
                  currency_quotations.date,
                  currency_quotations.value,
                  currency_quotations.created_at,
                  currency_quotations.updated_at
                 FROM currency_quotations
                WHERE ((currency_quotations.date <= date_series.date_series) AND (currency_quotations.currency_id = currencies.id))
                ORDER BY currency_quotations.date DESC
               LIMIT 1) t ON (true))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_euro_fund_interest_filled AS
       SELECT euro_funds.id AS euro_fund_id,
          date(date_series.date_series) AS date,
          t.minimal_rate,
          t.served_rate,
          t.year_length,
          (COALESCE(t.served_rate, t.minimal_rate) * ((1)::numeric - t.social_tax_rate)) AS rate_for_computation
         FROM ((generate_series((( SELECT min(interest_rates."from") AS min
                 FROM interest_rates))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN euro_funds)
           LEFT JOIN LATERAL ( SELECT interest_rates.id,
                  interest_rates.object_id,
                  interest_rates.object_type,
                  interest_rates.minimal_rate,
                  interest_rates."from",
                  interest_rates."to",
                  interest_rates.created_at,
                  interest_rates.updated_at,
                  interest_rates.served_rate,
                  interest_rates.social_tax_rate,
                  interest_rates.year_length
                 FROM interest_rates
                WHERE ((interest_rates."from" <= date_series.date_series) AND (interest_rates.object_id = euro_funds.id) AND ((interest_rates.object_type)::text = 'EuroFund'::text))
                ORDER BY interest_rates."to" DESC
               LIMIT 1) t ON (true))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled AS
       SELECT opcvm_funds.id AS opcvm_fund_id,
          date(date_series.date_series) AS date,
          t.value_original,
          t.value_currency,
          t.value_date
         FROM ((generate_series((( SELECT min(opcvm_quotations.date) AS min
                 FROM opcvm_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN opcvm_funds)
           JOIN LATERAL ( SELECT opcvm_quotations.id,
                  opcvm_quotations.opcvm_fund_id,
                  opcvm_quotations.value_original,
                  opcvm_quotations.date,
                  opcvm_quotations.created_at,
                  opcvm_quotations.updated_at,
                  opcvm_quotations.value_currency,
                  opcvm_quotations.value_date
                 FROM opcvm_quotations
                WHERE ((opcvm_quotations.date <= date_series.date_series) AND (opcvm_quotations.opcvm_fund_id = opcvm_funds.id))
                ORDER BY opcvm_quotations.date DESC
               LIMIT 1) t ON (true))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled_eur AS
       SELECT matview_opcvm_quotations_filled.opcvm_fund_id,
          matview_opcvm_quotations_filled.date,
              CASE
                  WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_opcvm_quotations_filled.value_original
                  ELSE (matview_opcvm_quotations_filled.value_original / matview_eur_to_currency.value)
              END AS value_original,
          'EUR'::character varying AS value_currency,
          matview_opcvm_quotations_filled.value_date
         FROM (matview_opcvm_quotations_filled
           LEFT JOIN matview_eur_to_currency ON (((matview_opcvm_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_opcvm_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_portfolio_transactions_eur AS
       SELECT portfolio_transactions.id,
          portfolio_transactions.fund_id,
          portfolio_transactions.shares,
          portfolio_transactions.portfolio_id,
          portfolio_transactions.done_at,
          portfolio_transactions.fund_type,
          portfolio_transactions.category,
              CASE
                  WHEN ((portfolio_transactions.amount_currency)::text = 'EUR'::text) THEN portfolio_transactions.amount_original
                  ELSE (portfolio_transactions.amount_original / matview_eur_to_currency_for_amount.value)
              END AS amount_original,
          'EUR'::character varying AS amount_currency,
          portfolio_transactions.amount_date,
              CASE
                  WHEN ((portfolio_transactions.shareprice_currency)::text = 'EUR'::text) THEN portfolio_transactions.shareprice_original
                  ELSE (portfolio_transactions.shareprice_original / matview_eur_to_currency_for_shareprice.value)
              END AS shareprice_original,
          'EUR'::character varying AS shareprice_currency,
          portfolio_transactions.shareprice_date
         FROM ((portfolio_transactions
           LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_amount ON (((portfolio_transactions.amount_date = matview_eur_to_currency_for_amount.date) AND ((portfolio_transactions.amount_currency)::text = (matview_eur_to_currency_for_amount.currency_name)::text))))
           LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_shareprice ON (((portfolio_transactions.amount_date = matview_eur_to_currency_for_shareprice.date) AND ((portfolio_transactions.amount_currency)::text = (matview_eur_to_currency_for_shareprice.currency_name)::text))))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur AS
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
                  WHEN (((matview_portfolio_transactions_eur.category)::text = 'Virement'::text) OR ((matview_portfolio_transactions_eur.category)::text = 'Arbitrage'::text)) THEN matview_portfolio_transactions_eur.amount_original
                  ELSE (0)::numeric
              END AS invested_original,
          matview_portfolio_transactions_eur.amount_currency AS invested_currency,
          matview_portfolio_transactions_eur.amount_date AS invested_date
         FROM matview_portfolio_transactions_eur
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur AS
       SELECT date(date_series.date_series) AS date,
          euro_funds.id AS fund_id,
          'EuroFund'::character varying AS fund_type,
          portfolios.id AS portfolio_id,
          NULL::numeric(15,5) AS shares,
          invested.invested,
          (((invested.invested + COALESCE(actual_pv.actual_pv, (0)::numeric)) + COALESCE(latent_pv_this_year.latent_pv_this_year, (0)::numeric)) + COALESCE(latent_pv_last_year.latent_pv_last_year, (0)::numeric)) AS current_value
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
                WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at < (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date))) latent_pv_last_year ON (true))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur AS
       SELECT date(date_series.date_series) AS date,
          opcvm_funds.id AS fund_id,
          'OpcvmFund'::character varying AS fund_type,
          portfolios.id AS portfolio_id,
          t.shares,
          t.invested,
          (matview_opcvm_quotations_filled_eur.value_original * t.shares) AS current_value
         FROM ((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
                 FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN opcvm_funds)
           CROSS JOIN portfolios)
           LEFT JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
                  matview_portfolio_transactions_with_investment_eur.portfolio_id,
                  sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
                  sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
                 FROM matview_portfolio_transactions_with_investment_eur
                WHERE (((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'OpcvmFund'::text) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))
                GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON (((t.fund_id = opcvm_funds.id) AND (t.portfolio_id = portfolios.id))))
           JOIN matview_opcvm_quotations_filled_eur ON (((opcvm_funds.id = matview_opcvm_quotations_filled_eur.opcvm_fund_id) AND (matview_opcvm_quotations_filled_eur.date = date(date_series.date_series)))))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_scpi_quotations_filled AS
       SELECT scpi_funds.id AS scpi_fund_id,
          date(date_series.date_series) AS date,
          t.value_original,
          t.value_currency,
          t.value_date
         FROM ((generate_series((( SELECT min(scpi_quotations.date) AS min
                 FROM scpi_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN scpi_funds)
           JOIN LATERAL ( SELECT scpi_quotations.id,
                  scpi_quotations.value_original,
                  scpi_quotations.value_currency,
                  scpi_quotations.value_date,
                  scpi_quotations.subscription_value_original,
                  scpi_quotations.subscription_value_currency,
                  scpi_quotations.subscription_value_date,
                  scpi_quotations.date,
                  scpi_quotations.scpi_fund_id,
                  scpi_quotations.created_at,
                  scpi_quotations.updated_at
                 FROM scpi_quotations
                WHERE ((scpi_quotations.date <= date_series.date_series) AND (scpi_quotations.scpi_fund_id = scpi_funds.id))
                ORDER BY scpi_quotations.date DESC
               LIMIT 1) t ON (true))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_scpi_quotations_filled_eur AS
       SELECT matview_scpi_quotations_filled.scpi_fund_id,
          matview_scpi_quotations_filled.date,
              CASE
                  WHEN ((matview_scpi_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_scpi_quotations_filled.value_original
                  ELSE (matview_scpi_quotations_filled.value_original / matview_eur_to_currency.value)
              END AS value_original,
          'EUR'::character varying AS value_currency,
          matview_scpi_quotations_filled.value_date
         FROM (matview_scpi_quotations_filled
           LEFT JOIN matview_eur_to_currency ON (((matview_scpi_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_scpi_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_portfolio_scpi_fund_history_eur AS
       SELECT date(date_series.date_series) AS date,
          scpi_funds.id AS fund_id,
          'ScpiFund'::character varying AS fund_type,
          portfolios.id AS portfolio_id,
          t.shares,
          t.invested,
          (matview_scpi_quotations_filled_eur.value_original * t.shares) AS current_value
         FROM ((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
                 FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN scpi_funds)
           CROSS JOIN portfolios)
           LEFT JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
                  matview_portfolio_transactions_with_investment_eur.portfolio_id,
                  sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
                  sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
                 FROM matview_portfolio_transactions_with_investment_eur
                WHERE (((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'ScpiFund'::text) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))
                GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON (((t.fund_id = scpi_funds.id) AND (t.portfolio_id = portfolios.id))))
           JOIN matview_scpi_quotations_filled_eur ON (((scpi_funds.id = matview_scpi_quotations_filled_eur.scpi_fund_id) AND (matview_scpi_quotations_filled_eur.date = date(date_series.date_series)))))
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_portfolio_history AS
       SELECT history.date,
          history.fund_id,
          history.fund_type,
          history.portfolio_id,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  ELSE history.shares
              END AS shares,
          history.invested,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  ELSE history.current_value
              END AS current_value,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN (- history.invested)
                  ELSE (history.current_value - history.invested)
              END AS pv,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  WHEN (history.invested = (0)::numeric) THEN NULL::numeric
                  ELSE ((history.current_value / history.invested) - (1)::numeric)
              END AS percent
         FROM ( SELECT matview_portfolio_euro_fund_history_eur.date,
                  matview_portfolio_euro_fund_history_eur.fund_id,
                  matview_portfolio_euro_fund_history_eur.fund_type,
                  matview_portfolio_euro_fund_history_eur.portfolio_id,
                  matview_portfolio_euro_fund_history_eur.shares,
                  matview_portfolio_euro_fund_history_eur.invested,
                  matview_portfolio_euro_fund_history_eur.current_value
                 FROM matview_portfolio_euro_fund_history_eur
              UNION
               SELECT matview_portfolio_opcvm_fund_history_eur.date,
                  matview_portfolio_opcvm_fund_history_eur.fund_id,
                  matview_portfolio_opcvm_fund_history_eur.fund_type,
                  matview_portfolio_opcvm_fund_history_eur.portfolio_id,
                  matview_portfolio_opcvm_fund_history_eur.shares,
                  matview_portfolio_opcvm_fund_history_eur.invested,
                  matview_portfolio_opcvm_fund_history_eur.current_value
                 FROM matview_portfolio_opcvm_fund_history_eur
              UNION
               SELECT matview_portfolio_scpi_fund_history_eur.date,
                  matview_portfolio_scpi_fund_history_eur.fund_id,
                  matview_portfolio_scpi_fund_history_eur.fund_type,
                  matview_portfolio_scpi_fund_history_eur.portfolio_id,
                  matview_portfolio_scpi_fund_history_eur.shares,
                  matview_portfolio_scpi_fund_history_eur.invested,
                  matview_portfolio_scpi_fund_history_eur.current_value
                 FROM matview_portfolio_scpi_fund_history_eur) history
        ORDER BY history.date, history.portfolio_id, history.fund_type, history.fund_id
        WITH NO DATA;

      CREATE MATERIALIZED VIEW matview_portfolio_performance AS
       SELECT matview_portfolio_history.date,
          matview_portfolio_history.portfolio_id,
          sum(matview_portfolio_history.invested) AS invested,
          sum(matview_portfolio_history.current_value) AS current_value,
          sum(matview_portfolio_history.pv) AS pv
         FROM matview_portfolio_history
        GROUP BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id
        ORDER BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id
        WITH NO DATA;
    )
  end
end
