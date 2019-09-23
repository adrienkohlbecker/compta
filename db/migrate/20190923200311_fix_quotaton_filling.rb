class FixQuotatonFilling < ActiveRecord::Migration
  def up
    execute %(
      CREATE VIEW public.view_scpi_quotations_filled AS
      WITH t_scpi_funds AS (
              SELECT scpi_funds.id,
                min(scpi_quotations.date) AS min_quotation,
                max(scpi_quotations.date) AS max_quotation
                FROM (public.scpi_funds
                  JOIN public.scpi_quotations ON ((scpi_quotations.scpi_fund_id = scpi_funds.id)))
              GROUP BY scpi_funds.id
            )
      SELECT t_scpi_funds.id AS scpi_fund_id,
        date(date_series.date_series) AS date,
        t_values.value_original,
        t_values.value_currency,
        date(date_series.date_series) AS value_date
        FROM ((t_scpi_funds
          CROSS JOIN LATERAL generate_series((t_scpi_funds.min_quotation)::timestamp with time zone, (t_scpi_funds.max_quotation)::timestamp with time zone, '1 day'::interval) date_series(date_series))
          JOIN LATERAL ( SELECT scpi_quotations.scpi_fund_id,
                scpi_quotations.date,
                scpi_quotations.value_original,
                scpi_quotations.value_currency,
                scpi_quotations.value_date
                FROM public.scpi_quotations
              WHERE ((scpi_quotations.scpi_fund_id = t_scpi_funds.id) AND (scpi_quotations.date <= date_series.date_series))
              ORDER BY scpi_quotations.date DESC
              LIMIT 1) t_values ON (true))
      UNION
      SELECT t_scpi_funds.id AS scpi_fund_id,
        date(date_series.date_series) AS date,
        t_values.value_original,
        t_values.value_currency,
        date(date_series.date_series) AS value_date
        FROM ((t_scpi_funds
          CROSS JOIN LATERAL generate_series((t_scpi_funds.max_quotation + '1 day'::interval), ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series))
          LEFT JOIN public.scpi_quotations t_values ON (((t_values.scpi_fund_id = t_scpi_funds.id) AND (t_values.date = t_scpi_funds.max_quotation))))
      ORDER BY 1, 2;
    )

    execute %(
      CREATE MATERIALIZED VIEW public.matview_scpi_quotations_filled AS
      SELECT view_scpi_quotations_filled.scpi_fund_id,
        view_scpi_quotations_filled.date,
        view_scpi_quotations_filled.value_original,
        view_scpi_quotations_filled.value_currency,
        view_scpi_quotations_filled.value_date
        FROM public.view_scpi_quotations_filled
      WITH NO DATA;
    )

    execute %(
      CREATE OR REPLACE VIEW public.view_scpi_quotations_filled_eur AS
       SELECT matview_scpi_quotations_filled.scpi_fund_id,
          matview_scpi_quotations_filled.date,
          (
              CASE
                  WHEN ((matview_scpi_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_scpi_quotations_filled.value_original
                  ELSE (matview_scpi_quotations_filled.value_original / matview_eur_to_currency.value)
              END)::numeric(15,5) AS value_original,
          'EUR'::character varying AS value_currency,
          matview_scpi_quotations_filled.value_date,
              CASE
                  WHEN ((matview_scpi_quotations_filled.value_currency)::text = 'EUR'::text) THEN NULL::numeric(15,5)
                  ELSE matview_scpi_quotations_filled.value_original
              END AS original_value_original,
              CASE
                  WHEN ((matview_scpi_quotations_filled.value_currency)::text = 'EUR'::text) THEN NULL::character varying
                  ELSE matview_scpi_quotations_filled.value_currency
              END AS original_value_currency,
              CASE
                  WHEN ((matview_scpi_quotations_filled.value_currency)::text = 'EUR'::text) THEN NULL::date
                  ELSE matview_scpi_quotations_filled.value_date
              END AS original_value_date
         FROM (public.matview_scpi_quotations_filled
           LEFT JOIN public.matview_eur_to_currency ON (((matview_scpi_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_scpi_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
        ORDER BY matview_scpi_quotations_filled.scpi_fund_id, matview_scpi_quotations_filled.date;
    )

    execute %(DROP MATERIALIZED VIEW matview_scpi_quotations_eur;)
    execute %(DROP VIEW view_scpi_quotations_eur;)

    execute %(CREATE INDEX index_matview_scpi_quotations_filled_on_scpi_fund_id_and_date ON public.matview_scpi_quotations_filled USING btree (scpi_fund_id, date);)

    execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_filled'
    execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_filled_eur'
  end
  def down
    execute %(
      CREATE VIEW public.view_scpi_quotations_eur AS
      SELECT scpi_quotations.scpi_fund_id,
        scpi_quotations.date,
        (
            CASE
                WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN scpi_quotations.value_original
                ELSE (scpi_quotations.value_original / matview_eur_to_currency.value)
            END)::numeric(15,5) AS value_original,
        'EUR'::character varying AS value_currency,
        scpi_quotations.value_date,
            CASE
                WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN NULL::numeric(15,5)
                ELSE scpi_quotations.value_original
            END AS original_value_original,
            CASE
                WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN NULL::character varying
                ELSE scpi_quotations.value_currency
            END AS original_value_currency,
            CASE
                WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN NULL::date
                ELSE scpi_quotations.value_date
            END AS original_value_date
        FROM (public.scpi_quotations
          LEFT JOIN public.matview_eur_to_currency ON (((scpi_quotations.value_date = matview_eur_to_currency.date) AND ((scpi_quotations.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
      ORDER BY scpi_quotations.scpi_fund_id, scpi_quotations.date;
    )

    execute %(
      CREATE MATERIALIZED VIEW public.matview_scpi_quotations_eur AS
      SELECT view_scpi_quotations_eur.scpi_fund_id,
          view_scpi_quotations_eur.date,
          view_scpi_quotations_eur.value_original,
          view_scpi_quotations_eur.value_currency,
          view_scpi_quotations_eur.value_date,
          view_scpi_quotations_eur.original_value_original,
          view_scpi_quotations_eur.original_value_currency,
          view_scpi_quotations_eur.original_value_date
        FROM public.view_scpi_quotations_eur
        WITH NO DATA;
    )

    execute %(
      CREATE OR REPLACE VIEW public.view_scpi_quotations_filled_eur AS
       WITH t_scpi_funds AS (
               SELECT scpi_funds.id,
                  min(matview_scpi_quotations_eur.date) AS min_quotation,
                  max(matview_scpi_quotations_eur.date) AS max_quotation
                 FROM (public.scpi_funds
                   JOIN public.matview_scpi_quotations_eur ON ((matview_scpi_quotations_eur.scpi_fund_id = scpi_funds.id)))
                GROUP BY scpi_funds.id
              )
       SELECT t_scpi_funds.id AS scpi_fund_id,
          date(date_series.date_series) AS date,
          t_values.value_original,
          t_values.value_currency,
          t_values.value_date,
          t_values.original_value_original,
          t_values.original_value_currency,
          t_values.original_value_date
         FROM ((t_scpi_funds
           CROSS JOIN LATERAL generate_series((t_scpi_funds.min_quotation)::timestamp with time zone, (t_scpi_funds.max_quotation)::timestamp with time zone, '1 day'::interval) date_series(date_series))
           JOIN LATERAL ( SELECT matview_scpi_quotations_eur.scpi_fund_id,
                  matview_scpi_quotations_eur.date,
                  matview_scpi_quotations_eur.value_original,
                  matview_scpi_quotations_eur.value_currency,
                  matview_scpi_quotations_eur.value_date,
                  matview_scpi_quotations_eur.original_value_original,
                  matview_scpi_quotations_eur.original_value_currency,
                  matview_scpi_quotations_eur.original_value_date
                 FROM public.matview_scpi_quotations_eur
                WHERE ((matview_scpi_quotations_eur.scpi_fund_id = t_scpi_funds.id) AND (matview_scpi_quotations_eur.date <= date_series.date_series))
                ORDER BY matview_scpi_quotations_eur.date DESC
               LIMIT 1) t_values ON (true))
      UNION
       SELECT t_scpi_funds.id AS scpi_fund_id,
          date(date_series.date_series) AS date,
          t_values.value_original,
          t_values.value_currency,
          t_values.value_date,
          t_values.original_value_original,
          t_values.original_value_currency,
          t_values.original_value_date
         FROM ((t_scpi_funds
           CROSS JOIN LATERAL generate_series((t_scpi_funds.max_quotation + '1 day'::interval), ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series))
           LEFT JOIN public.matview_scpi_quotations_eur t_values ON (((t_values.scpi_fund_id = t_scpi_funds.id) AND (t_values.date = t_scpi_funds.max_quotation))))
        ORDER BY 1, 2;
    )

    execute %(DROP MATERIALIZED VIEW matview_scpi_quotations_filled;)
    execute %(DROP VIEW view_scpi_quotations_filled;)

    execute %(CREATE INDEX index_matview_scpi_quotations_eur_on_scpi_fund_id_and_date ON public.matview_scpi_quotations_eur USING btree (scpi_fund_id, date);)

    execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_eur'
    execute 'REFRESH MATERIALIZED VIEW matview_scpi_quotations_filled_eur'
  end
end
