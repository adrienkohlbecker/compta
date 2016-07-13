class DropViewsAndAddIndex < ActiveRecord::Migration
  def up
    execute 'DROP MATERIALIZED VIEW matview_opcvm_quotations_filled'
    execute 'DROP VIEW view_opcvm_quotations_filled'
    execute 'CREATE INDEX index_matview_opcvm_quotations_filled_eur_on_opcvm_fund_id_and_date ON matview_opcvm_quotations_filled_eur USING btree(opcvm_fund_id, date);'
  end
  def down
    execute 'DROP INDEX index_matview_opcvm_quotations_filled_eur_on_opcvm_fund_id_and_date'
    execute %(
    CREATE OR REPLACE VIEW public.view_opcvm_quotations_filled AS
      SELECT opcvm_funds.id AS opcvm_fund_id,
        date(date_series.date_series) AS date,
        t.value_original,
        t.value_currency,
        t.value_date
       FROM generate_series((( SELECT min(opcvm_quotations.date) AS min
               FROM opcvm_quotations))::timestamp without time zone, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series(date_series)
         CROSS JOIN opcvm_funds
         JOIN LATERAL ( SELECT opcvm_quotations.id,
                opcvm_quotations.opcvm_fund_id,
                opcvm_quotations.value_original,
                opcvm_quotations.date,
                opcvm_quotations.created_at,
                opcvm_quotations.updated_at,
                opcvm_quotations.value_currency,
                opcvm_quotations.value_date
               FROM opcvm_quotations
              WHERE opcvm_quotations.date <= date_series.date_series AND opcvm_quotations.opcvm_fund_id = opcvm_funds.id
              ORDER BY opcvm_quotations.date DESC
             LIMIT 1) t ON true;
    )
    execute %(
      CREATE MATERIALIZED VIEW public.matview_opcvm_quotations_filled AS
       SELECT view_opcvm_quotations_filled.opcvm_fund_id,
          view_opcvm_quotations_filled.date,
          view_opcvm_quotations_filled.value_original,
          view_opcvm_quotations_filled.value_currency,
          view_opcvm_quotations_filled.value_date
         FROM view_opcvm_quotations_filled
    )
  end
end
