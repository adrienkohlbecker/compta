# frozen_string_literal: true
class CreateMatviewOpcvmQuotationsFilledEurs < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled_eur AS (
      SELECT matview_opcvm_quotations_filled.opcvm_fund_id, matview_opcvm_quotations_filled.date,
             CASE WHEN matview_opcvm_quotations_filled.value_currency = 'EUR' THEN matview_opcvm_quotations_filled.value_original
                  ELSE matview_opcvm_quotations_filled.value_original / matview_eur_to_currency.value
             END AS value_original,
             'EUR'::character varying AS value_currency,
             matview_opcvm_quotations_filled.value_date
      FROM matview_opcvm_quotations_filled
      LEFT OUTER JOIN matview_eur_to_currency ON matview_opcvm_quotations_filled.value_date = matview_eur_to_currency.date AND matview_opcvm_quotations_filled.value_currency = matview_eur_to_currency.currency_name
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_opcvm_quotations_filled_eur'
  end
end
