class CreateMatviewEuroFundInterestFilleds < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_euro_fund_interest_filled AS (
      SELECT euro_funds.id AS euro_fund_id, date_series.date, t.minimal_rate, t.served_rate, t.year_length,
             COALESCE(t.served_rate, t.minimal_rate) * (1 - t.social_tax_rate) AS rate_for_computation
      FROM generate_series(
        (SELECT min(interest_rates.from) FROM interest_rates),
        transaction_timestamp()::date + '30 days'::interval,
        '1 day'::interval
      ) date_series
      CROSS JOIN euro_funds
      LEFT OUTER JOIN LATERAL (
        SELECT interest_rates.*
        FROM interest_rates
        WHERE interest_rates.from <= date_series AND interest_rates.object_id = euro_funds.id AND object_type = 'EuroFund'
        ORDER BY interest_rates.to DESC LIMIT 1
      ) t ON TRUE
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_euro_fund_interest_filled'
  end
end
