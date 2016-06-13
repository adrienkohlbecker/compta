# frozen_string_literal: true
class CreateMatviewEurToCurrencies < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_eur_to_currency AS (
      SELECT currencies.id AS currency_id, currencies.name AS currency_name, date_series.date, t.value
      FROM generate_series(
        (SELECT min(date) FROM currency_quotations),
        transaction_timestamp()::date + '30 days'::interval,
        '1 day'::interval
      ) date_series
      CROSS JOIN currencies
      LEFT OUTER JOIN LATERAL (
        SELECT currency_quotations.*
        FROM currency_quotations
        WHERE currency_quotations.date <= date_series AND currency_quotations.currency_id = currencies.id
        ORDER BY currency_quotations.date DESC LIMIT 1
      ) t ON TRUE
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_eur_to_currency'
  end
end
