class UpdateViewEurToCurrency < ActiveRecord::Migration
  def up
    execute %(
      CREATE OR REPLACE VIEW view_eur_to_currency AS
        WITH t_currencies_tmp AS
          (SELECT currencies.id, currencies.name, min(currency_quotations.date) AS min, max(currency_quotations.date) AS max FROM currencies JOIN currency_quotations ON currency_quotations.currency_id = currencies.id GROUP BY currencies.id, currencies.name),
        t_currencies AS
          (SELECT t_currencies_tmp.id, t_currencies_tmp.name, t_currencies_tmp.min, t_currencies_tmp.max, currency_quotations.value AS value_at_max_date FROM t_currencies_tmp JOIN currency_quotations ON currency_quotations.currency_id = t_currencies_tmp.id WHERE currency_quotations.date = t_currencies_tmp.max)
        (
          SELECT
            t_currencies.id AS currency_id,
            t_currencies.name AS currency_name,
            date(date_series.date_series) AS date,
            t_values.value
          FROM t_currencies
          CROSS JOIN generate_series(t_currencies.min, t_currencies.max, '1 day'::interval) date_series
          JOIN LATERAL (
            SELECT value FROM currency_quotations
            WHERE currency_quotations.currency_id = t_currencies.id
              AND (currency_quotations.date >= date_series.date_series)
              ORDER BY currency_quotations.date ASC
              LIMIT 1
          ) t_values ON true
        )
        UNION
        (
          SELECT
            t_currencies.id AS currency_id,
            t_currencies.name AS currency_name,
            date(date_series.date_series) AS date,
            t_currencies.value_at_max_date AS value
          FROM t_currencies
          CROSS JOIN generate_series(t_currencies.max + '1 day'::interval, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series
        )
        ORDER BY currency_id, date
    )
    execute 'REFRESH MATERIALIZED VIEW matview_eur_to_currency'
  end
  def down
    execute %(
      CREATE OR REPLACE VIEW view_eur_to_currency AS
       SELECT currencies.id AS currency_id,
          currencies.name AS currency_name,
          date(date_series.date_series) AS date,
          t.value
         FROM ((generate_series((( SELECT min(currency_quotations.date) AS min
                 FROM currency_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN currencies)
           LEFT JOIN LATERAL ( SELECT currency_quotations.id,
                  currency_quotations.currency_id,
                  currency_quotations.date,
                  currency_quotations.value,
                  currency_quotations.created_at,
                  currency_quotations.updated_at
                 FROM currency_quotations
                WHERE ((currency_quotations.date <= date_series.date_series) AND (currency_quotations.currency_id = currencies.id))
                ORDER BY currency_quotations.date DESC
               LIMIT 1) t ON (true))
    )
    execute 'REFRESH MATERIALIZED VIEW matview_eur_to_currency'
  end
end
