class UpdateQuotationSort < ActiveRecord::Migration
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
              WHERE ((opcvm_quotations.opcvm_fund_id = t_opcvm_funds.id) AND (opcvm_quotations.date <= date_series.date_series))
              ORDER BY opcvm_quotations.date DESC
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

    execute %(REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled;)
  end

  def down
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

    execute %(REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled;)
  end
end
