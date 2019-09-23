class FixQuotatonFillinf < ActiveRecord::Migration
  def up
    execute %(
      CREATE OR REPLACE VIEW public.view_opcvm_quotations_filled AS
      WITH t_opcvm_funds AS (
              SELECT opcvm_funds.id,
                min(opcvm_quotations.date) AS min_quotation,
                max(opcvm_quotations.date) AS max_quotation
                FROM (public.opcvm_funds
                  JOIN public.opcvm_quotations ON ((opcvm_quotations.opcvm_fund_id = opcvm_funds.id)))
              GROUP BY opcvm_funds.id
            )
      SELECT t_opcvm_funds.id AS opcvm_fund_id,
        date(date_series.date_series) AS date,
        t_values.value_original,
        t_values.value_currency,
        date(date_series.date_series) AS value_date
        FROM ((t_opcvm_funds
          CROSS JOIN LATERAL generate_series((t_opcvm_funds.min_quotation)::timestamp with time zone, (t_opcvm_funds.max_quotation)::timestamp with time zone, '1 day'::interval) date_series(date_series))
          JOIN LATERAL ( SELECT opcvm_quotations.opcvm_fund_id,
                opcvm_quotations.date,
                opcvm_quotations.value_original,
                opcvm_quotations.value_currency,
                opcvm_quotations.value_date
                FROM public.opcvm_quotations
              WHERE ((opcvm_quotations.opcvm_fund_id = t_opcvm_funds.id) AND (opcvm_quotations.date >= date_series.date_series))
              ORDER BY opcvm_quotations.date
              LIMIT 1) t_values ON (true))
      UNION
      SELECT t_opcvm_funds.id AS opcvm_fund_id,
        date(date_series.date_series) AS date,
        t_values.value_original,
        t_values.value_currency,
        date(date_series.date_series) AS value_date
        FROM ((t_opcvm_funds
          CROSS JOIN LATERAL generate_series((t_opcvm_funds.max_quotation + '1 day'::interval), ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series))
          LEFT JOIN public.opcvm_quotations t_values ON (((t_values.opcvm_fund_id = t_opcvm_funds.id) AND (t_values.date = t_opcvm_funds.max_quotation))))
      ORDER BY 1, 2;
    )

    execute %(
      CREATE MATERIALIZED VIEW public.matview_opcvm_quotations_filled AS
      SELECT view_opcvm_quotations_filled.opcvm_fund_id,
        view_opcvm_quotations_filled.date,
        view_opcvm_quotations_filled.value_original,
        view_opcvm_quotations_filled.value_currency,
        view_opcvm_quotations_filled.value_date
        FROM public.view_opcvm_quotations_filled
      WITH NO DATA;
    )

    execute %(
      CREATE OR REPLACE VIEW public.view_opcvm_quotations_filled_eur AS
      SELECT matview_opcvm_quotations_filled.opcvm_fund_id,
        matview_opcvm_quotations_filled.date,
        (
            CASE
                WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_opcvm_quotations_filled.value_original
                ELSE (matview_opcvm_quotations_filled.value_original / matview_eur_to_currency.value)
            END)::numeric(15,5) AS value_original,
        'EUR'::character varying AS value_currency,
        matview_opcvm_quotations_filled.value_date,
            CASE
                WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN NULL::numeric(15,5)
                ELSE matview_opcvm_quotations_filled.value_original
            END AS original_value_original,
            CASE
                WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN NULL::character varying
                ELSE matview_opcvm_quotations_filled.value_currency
            END AS original_value_currency,
            CASE
                WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN NULL::date
                ELSE matview_opcvm_quotations_filled.value_date
            END AS original_value_date
        FROM (public.matview_opcvm_quotations_filled
          LEFT JOIN public.matview_eur_to_currency ON (((matview_opcvm_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_opcvm_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
      ORDER BY matview_opcvm_quotations_filled.opcvm_fund_id, matview_opcvm_quotations_filled.date;
    )

    execute %q(DROP MATERIALIZED VIEW matview_opcvm_quotations_eur;)
    execute %q(DROP VIEW view_opcvm_quotations_eur;)

    execute %(CREATE INDEX index_matview_opcvm_quotations_filled_on_opcvm_fund_id_and_date ON public.matview_opcvm_quotations_filled USING btree (opcvm_fund_id, date);)

    execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled'
    execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled_eur'
  end

  def down
    execute %(
      CREATE OR REPLACE VIEW public.view_opcvm_quotations_eur AS
      SELECT opcvm_quotations.opcvm_fund_id,
        opcvm_quotations.date,
        (
            CASE
                WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN opcvm_quotations.value_original
                ELSE (opcvm_quotations.value_original / matview_eur_to_currency.value)
            END)::numeric(15,5) AS value_original,
        'EUR'::character varying AS value_currency,
        opcvm_quotations.value_date,
            CASE
                WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN NULL::numeric(15,5)
                ELSE opcvm_quotations.value_original
            END AS original_value_original,
            CASE
                WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN NULL::character varying
                ELSE opcvm_quotations.value_currency
            END AS original_value_currency,
            CASE
                WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN NULL::date
                ELSE opcvm_quotations.value_date
            END AS original_value_date
        FROM (public.opcvm_quotations
          LEFT JOIN public.matview_eur_to_currency ON (((opcvm_quotations.value_date = matview_eur_to_currency.date) AND ((opcvm_quotations.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
      ORDER BY opcvm_quotations.opcvm_fund_id, opcvm_quotations.date;
    )

    execute %(
      CREATE MATERIALIZED VIEW public.matview_opcvm_quotations_eur AS
      SELECT view_opcvm_quotations_eur.opcvm_fund_id,
        view_opcvm_quotations_eur.date,
        view_opcvm_quotations_eur.value_original,
        view_opcvm_quotations_eur.value_currency,
        view_opcvm_quotations_eur.value_date,
        view_opcvm_quotations_eur.original_value_original,
        view_opcvm_quotations_eur.original_value_currency,
        view_opcvm_quotations_eur.original_value_date
        FROM public.view_opcvm_quotations_eur
      WITH NO DATA;
    )

    execute %(
      CREATE OR REPLACE VIEW public.view_opcvm_quotations_filled_eur AS
      WITH t_opcvm_funds AS (
              SELECT opcvm_funds.id,
                min(matview_opcvm_quotations_eur.date) AS min_quotation,
                max(matview_opcvm_quotations_eur.date) AS max_quotation
                FROM (public.opcvm_funds
                  JOIN public.matview_opcvm_quotations_eur ON ((matview_opcvm_quotations_eur.opcvm_fund_id = opcvm_funds.id)))
              GROUP BY opcvm_funds.id
            )
      SELECT t_opcvm_funds.id AS opcvm_fund_id,
        date(date_series.date_series) AS date,
        t_values.value_original,
        t_values.value_currency,
        t_values.value_date,
        t_values.original_value_original,
        t_values.original_value_currency,
        t_values.original_value_date
        FROM ((t_opcvm_funds
          CROSS JOIN LATERAL generate_series((t_opcvm_funds.min_quotation)::timestamp with time zone, (t_opcvm_funds.max_quotation)::timestamp with time zone, '1 day'::interval) date_series(date_series))
          JOIN LATERAL ( SELECT matview_opcvm_quotations_eur.opcvm_fund_id,
                matview_opcvm_quotations_eur.date,
                matview_opcvm_quotations_eur.value_original,
                matview_opcvm_quotations_eur.value_currency,
                matview_opcvm_quotations_eur.value_date,
                matview_opcvm_quotations_eur.original_value_original,
                matview_opcvm_quotations_eur.original_value_currency,
                matview_opcvm_quotations_eur.original_value_date
                FROM public.matview_opcvm_quotations_eur
              WHERE ((matview_opcvm_quotations_eur.opcvm_fund_id = t_opcvm_funds.id) AND (matview_opcvm_quotations_eur.date >= date_series.date_series))
              ORDER BY matview_opcvm_quotations_eur.date
              LIMIT 1) t_values ON (true))
      UNION
      SELECT t_opcvm_funds.id AS opcvm_fund_id,
        date(date_series.date_series) AS date,
        t_values.value_original,
        t_values.value_currency,
        t_values.value_date,
        t_values.original_value_original,
        t_values.original_value_currency,
        t_values.original_value_date
        FROM ((t_opcvm_funds
          CROSS JOIN LATERAL generate_series((t_opcvm_funds.max_quotation + '1 day'::interval), ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series))
          LEFT JOIN public.matview_opcvm_quotations_eur t_values ON (((t_values.opcvm_fund_id = t_opcvm_funds.id) AND (t_values.date = t_opcvm_funds.max_quotation))))
      ORDER BY 1, 2;
    )

    execute %q(DROP MATERIALIZED VIEW matview_opcvm_quotations_filled;)
    execute %q(DROP VIEW view_opcvm_quotations_filled;)

    execute %(CREATE INDEX index_matview_opcvm_quotations_eur_on_opcvm_fund_id_and_date ON public.matview_opcvm_quotations_eur USING btree (opcvm_fund_id, date);)

    execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_eur'
    execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled_eur'
  end
end
