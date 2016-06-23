# frozen_string_literal: true
class CreateMatviewScpiQuotationsFilledEur < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_scpi_quotations_filled_eur AS (
      SELECT matview_scpi_quotations_filled.scpi_fund_id, matview_scpi_quotations_filled.date,
             CASE WHEN matview_scpi_quotations_filled.value_currency = 'EUR' THEN matview_scpi_quotations_filled.value_original
                  ELSE matview_scpi_quotations_filled.value_original / matview_eur_to_currency.value
             END AS value_original,
             'EUR'::character varying AS value_currency,
             matview_scpi_quotations_filled.value_date
      FROM matview_scpi_quotations_filled
      LEFT OUTER JOIN matview_eur_to_currency ON matview_scpi_quotations_filled.value_date = matview_eur_to_currency.date AND matview_scpi_quotations_filled.value_currency = matview_eur_to_currency.currency_name
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_scpi_quotations_filled_eur'
  end
end
