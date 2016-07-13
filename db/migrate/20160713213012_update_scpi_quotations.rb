class UpdateScpiQuotations < ActiveRecord::Migration
  def up
    execute %(
      CREATE VIEW view_scpi_quotations_eur AS
        SELECT scpi_quotations.scpi_fund_id,
          scpi_quotations.date,
              (CASE
                  WHEN scpi_quotations.value_currency::text = 'EUR'::text THEN scpi_quotations.value_original
                  ELSE scpi_quotations.value_original / matview_eur_to_currency.value
              END)::numeric(15,5) AS value_original,
          'EUR'::character varying AS value_currency,
          scpi_quotations.value_date,
          (CASE
              WHEN scpi_quotations.value_currency::text = 'EUR'::text THEN NULL::numeric(15,5)
              ELSE scpi_quotations.value_original
          END)::numeric(15,5) AS original_value_original,
          (CASE
              WHEN scpi_quotations.value_currency::text = 'EUR'::text THEN NULL::character varying
              ELSE scpi_quotations.value_currency
          END)::character varying AS original_value_currency,
          (CASE
              WHEN scpi_quotations.value_currency::text = 'EUR'::text THEN NULL::date
              ELSE scpi_quotations.value_date
          END)::date AS original_value_date
         FROM scpi_quotations
           LEFT JOIN matview_eur_to_currency ON scpi_quotations.value_date = matview_eur_to_currency.date AND scpi_quotations.value_currency = matview_eur_to_currency.currency_name
         ORDER BY scpi_fund_id, date;
    )
    execute 'CREATE MATERIALIZED VIEW matview_scpi_quotations_eur AS SELECT * FROM view_scpi_quotations_eur'
    execute 'CREATE INDEX index_matview_scpi_quotations_eur_on_scpi_fund_id_and_date ON matview_scpi_quotations_eur USING btree(scpi_fund_id, date);'
    execute %(
      CREATE OR REPLACE VIEW view_scpi_quotations_filled_eur AS
        WITH t_scpi_funds AS (
          SELECT scpi_funds.id, min(matview_scpi_quotations_eur.date) AS min_quotation, max(matview_scpi_quotations_eur.date) AS max_quotation FROM scpi_funds JOIN matview_scpi_quotations_eur ON matview_scpi_quotations_eur.scpi_fund_id = scpi_funds.id
          GROUP BY scpi_funds.id
        )
        (
        SELECT
           t_scpi_funds.id AS scpi_fund_id,
           date(date_series.date_series) AS date,
           t_values.value_original,
           t_values.value_currency,
           t_values.value_date,
           t_values.original_value_original,
           t_values.original_value_currency,
           t_values.original_value_date
        FROM t_scpi_funds
        CROSS JOIN generate_series(t_scpi_funds.min_quotation, t_scpi_funds.max_quotation, '1 day'::interval) date_series
        JOIN LATERAL (
          SELECT * FROM matview_scpi_quotations_eur
          WHERE matview_scpi_quotations_eur.scpi_fund_id = t_scpi_funds.id
          AND (matview_scpi_quotations_eur.date <= date_series.date_series)
          ORDER BY matview_scpi_quotations_eur.date DESC
          LIMIT 1
        ) t_values ON true
        )
        UNION
        (
        SELECT
           t_scpi_funds.id AS scpi_fund_id,
           date(date_series.date_series) AS date,
           t_values.value_original,
           t_values.value_currency,
           t_values.value_date,
           t_values.original_value_original,
           t_values.original_value_currency,
           t_values.original_value_date
        FROM t_scpi_funds
        CROSS JOIN generate_series(t_scpi_funds.max_quotation + '1 day'::interval, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series
        LEFT JOIN matview_scpi_quotations_eur t_values ON t_values.scpi_fund_id = t_scpi_funds.id AND t_values.date = t_scpi_funds.max_quotation
        )
        ORDER BY scpi_fund_id, date
    )
    execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_filled_eur'
    execute 'DROP MATERIALIZED VIEW matview_scpi_quotations_filled'
    execute 'DROP VIEW view_scpi_quotations_filled'
    execute 'CREATE INDEX index_matview_scpi_quotations_filled_eur_on_scpi_fund_id_and_date ON matview_scpi_quotations_filled_eur USING btree(scpi_fund_id, date);'
  end
  def down
    execute 'DROP INDEX index_matview_scpi_quotations_filled_eur_on_scpi_fund_id_and_date'
    execute %(
    CREATE OR REPLACE VIEW public.view_scpi_quotations_filled AS
      SELECT scpi_funds.id AS scpi_fund_id,
        date(date_series.date_series) AS date,
        t.value_original,
        t.value_currency,
        t.value_date
       FROM generate_series((( SELECT min(scpi_quotations.date) AS min
               FROM scpi_quotations))::timestamp without time zone, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series(date_series)
         CROSS JOIN scpi_funds
         JOIN LATERAL ( SELECT scpi_quotations.id,
                scpi_quotations.scpi_fund_id,
                scpi_quotations.value_original,
                scpi_quotations.date,
                scpi_quotations.created_at,
                scpi_quotations.updated_at,
                scpi_quotations.value_currency,
                scpi_quotations.value_date
               FROM scpi_quotations
              WHERE scpi_quotations.date <= date_series.date_series AND scpi_quotations.scpi_fund_id = scpi_funds.id
              ORDER BY scpi_quotations.date DESC
             LIMIT 1) t ON true;
    )
    execute %(
      CREATE MATERIALIZED VIEW public.matview_scpi_quotations_filled AS
       SELECT view_scpi_quotations_filled.scpi_fund_id,
          view_scpi_quotations_filled.date,
          view_scpi_quotations_filled.value_original,
          view_scpi_quotations_filled.value_currency,
          view_scpi_quotations_filled.value_date
         FROM view_scpi_quotations_filled
    )
    execute 'DROP INDEX index_matview_scpi_quotations_eur_on_scpi_fund_id_and_date'
    execute %(
      CREATE OR REPLACE VIEW view_scpi_quotations_filled_eur AS
        SELECT matview_scpi_quotations_filled.scpi_fund_id,
           matview_scpi_quotations_filled.date,
               (CASE
                   WHEN ((matview_scpi_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_scpi_quotations_filled.value_original
                   ELSE (matview_scpi_quotations_filled.value_original / matview_eur_to_currency.value)
               END)::numeric(15,5) AS value_original,
           'EUR'::character varying AS value_currency,
           matview_scpi_quotations_filled.value_date,
           NULL::numeric(15,5) AS original_value_original,
           NULL::character varying AS original_value_currency,
           NULL::date AS original_value_date
          FROM (matview_scpi_quotations_filled
            LEFT JOIN matview_eur_to_currency ON (((matview_scpi_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_scpi_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))));
    )
    execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_filled_eur'
    execute 'DROP MATERIALIZED VIEW matview_scpi_quotations_eur'
    execute 'DROP VIEW view_scpi_quotations_eur'
  end
end
