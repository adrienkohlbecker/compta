class CreateViewOpcvmQuotationsEur < ActiveRecord::Migration
  def up
    execute %(
      CREATE VIEW view_opcvm_quotations_eur AS
        SELECT opcvm_quotations.opcvm_fund_id,
          opcvm_quotations.date,
              (CASE
                  WHEN opcvm_quotations.value_currency::text = 'EUR'::text THEN opcvm_quotations.value_original
                  ELSE opcvm_quotations.value_original / matview_eur_to_currency.value
              END)::numeric(15,5) AS value_original,
          'EUR'::character varying AS value_currency,
          opcvm_quotations.value_date,
          (CASE
              WHEN opcvm_quotations.value_currency::text = 'EUR'::text THEN NULL::numeric(15,5)
              ELSE opcvm_quotations.value_original
          END)::numeric(15,5) AS original_value_original,
          (CASE
              WHEN opcvm_quotations.value_currency::text = 'EUR'::text THEN NULL::character varying
              ELSE opcvm_quotations.value_currency
          END)::character varying AS original_value_currency,
          (CASE
              WHEN opcvm_quotations.value_currency::text = 'EUR'::text THEN NULL::date
              ELSE opcvm_quotations.value_date
          END)::date AS original_value_date
         FROM opcvm_quotations
           LEFT JOIN matview_eur_to_currency ON opcvm_quotations.value_date = matview_eur_to_currency.date AND opcvm_quotations.value_currency = matview_eur_to_currency.currency_name
         ORDER BY opcvm_fund_id, date;
    )
    execute 'CREATE MATERIALIZED VIEW matview_opcvm_quotations_eur AS SELECT * FROM view_opcvm_quotations_eur'
  end
  def down
    execute 'DROP MATERIALIZED VIEW matview_opcvm_quotations_eur'
    execute 'DROP VIEW view_opcvm_quotations_eur'
  end
end
