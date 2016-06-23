# frozen_string_literal: true
class CreateMatviewScpiQuotationsFilled < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_scpi_quotations_filled AS (
      SELECT scpi_funds.id AS scpi_fund_id, date_series.date, t.value_original, t.value_currency, t.value_date
      FROM generate_series(
         (SELECT min(date) FROM scpi_quotations),
         transaction_timestamp()::date + '30 days'::interval,
        '1 day'::interval
      ) date_series
      CROSS JOIN scpi_funds
      JOIN LATERAL (
        SELECT scpi_quotations.*
        FROM scpi_quotations
        WHERE scpi_quotations.date <= date_series AND scpi_quotations.scpi_fund_id = scpi_funds.id
        ORDER BY scpi_quotations.date DESC LIMIT 1
      ) t ON TRUE
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_scpi_quotations_filled'
  end
end
