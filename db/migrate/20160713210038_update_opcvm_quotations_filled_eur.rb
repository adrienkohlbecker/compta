class UpdateOpcvmQuotationsFilledEur < ActiveRecord::Migration
  def up
    execute 'CREATE INDEX index_matview_opcvm_quotations_eur_on_opcvm_fund_id_and_date ON matview_opcvm_quotations_eur USING btree(opcvm_fund_id, date);'
    execute %(
      CREATE OR REPLACE VIEW view_opcvm_quotations_filled_eur AS
        WITH t_opcvm_funds AS (
          SELECT opcvm_funds.id, min(matview_opcvm_quotations_eur.date) AS min_quotation, max(matview_opcvm_quotations_eur.date) AS max_quotation FROM opcvm_funds JOIN matview_opcvm_quotations_eur ON matview_opcvm_quotations_eur.opcvm_fund_id = opcvm_funds.id
          GROUP BY opcvm_funds.id
        )
        (
        SELECT
           t_opcvm_funds.id AS opcvm_fund_id,
           date(date_series.date_series) AS date,
           t_values.value_original,
           t_values.value_currency,
           t_values.value_date,
           t_values.original_value_original,
           t_values.original_value_currency,
           t_values.original_value_date
        FROM t_opcvm_funds
        CROSS JOIN generate_series(t_opcvm_funds.min_quotation, t_opcvm_funds.max_quotation, '1 day'::interval) date_series
        JOIN LATERAL (
          SELECT * FROM matview_opcvm_quotations_eur
          WHERE matview_opcvm_quotations_eur.opcvm_fund_id = t_opcvm_funds.id
          AND (matview_opcvm_quotations_eur.date >= date_series.date_series)
          ORDER BY matview_opcvm_quotations_eur.date ASC
          LIMIT 1
        ) t_values ON true
        )
        UNION
        (
        SELECT
           t_opcvm_funds.id AS opcvm_fund_id,
           date(date_series.date_series) AS date,
           t_values.value_original,
           t_values.value_currency,
           t_values.value_date,
           t_values.original_value_original,
           t_values.original_value_currency,
           t_values.original_value_date
        FROM t_opcvm_funds
        CROSS JOIN generate_series(t_opcvm_funds.max_quotation + '1 day'::interval, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series
        LEFT JOIN matview_opcvm_quotations_eur t_values ON t_values.opcvm_fund_id = t_opcvm_funds.id AND t_values.date = t_opcvm_funds.max_quotation
        )
        ORDER BY opcvm_fund_id, date
    )
    execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled_eur'
  end
  def down
    execute 'DROP INDEX index_matview_opcvm_quotations_eur_on_opcvm_fund_id_and_date'
    execute %(
      CREATE OR REPLACE VIEW view_opcvm_quotations_filled_eur AS
        SELECT matview_opcvm_quotations_filled.opcvm_fund_id,
           matview_opcvm_quotations_filled.date,
               (CASE
                   WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_opcvm_quotations_filled.value_original
                   ELSE (matview_opcvm_quotations_filled.value_original / matview_eur_to_currency.value)
               END)::numeric(15,5) AS value_original,
           'EUR'::character varying AS value_currency,
           matview_opcvm_quotations_filled.value_date,
           NULL::numeric(15,5) AS original_value_original,
           NULL::character varying AS original_value_currency,
           NULL::date AS original_value_date
          FROM (matview_opcvm_quotations_filled
            LEFT JOIN matview_eur_to_currency ON (((matview_opcvm_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_opcvm_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))));
    )
    execute 'REFRESH MATERIALIZED VIEW matview_opcvm_quotations_filled_eur'
  end
end
