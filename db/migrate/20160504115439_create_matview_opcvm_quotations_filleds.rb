class CreateMatviewOpcvmQuotationsFilleds < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled AS (
      SELECT opcvm_funds.id AS opcvm_fund_id, date_series.date, t.value_original, t.value_currency, t.value_date
      FROM generate_series(
         (SELECT min(date) FROM opcvm_quotations),
         transaction_timestamp()::date + '30 days'::interval,
        '1 day'::interval
      ) date_series
      CROSS JOIN opcvm_funds
      JOIN LATERAL (
        SELECT opcvm_quotations.*
        FROM opcvm_quotations
        WHERE opcvm_quotations.date <= date_series AND opcvm_quotations.opcvm_fund_id = opcvm_funds.id
        ORDER BY opcvm_quotations.date DESC LIMIT 1
      ) t ON TRUE
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_opcvm_quotations_filled'
  end
end
