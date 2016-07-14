class UpdateEuroFundInterest < ActiveRecord::Migration
  def up
    execute %(
      CREATE OR REPLACE VIEW view_euro_fund_interest_filled AS
        WITH t_euro_funds AS (
          SELECT euro_funds.id, max(interest_rates.to) AS max_to FROM euro_funds JOIN interest_rates ON interest_rates.object_id = euro_funds.id AND interest_rates.object_type = 'EuroFund' GROUP BY euro_funds.id
        ),
        t_interest_rates AS (
          SELECT
        	t_euro_funds.id AS euro_fund_id,
        	interest_rates.from,
        	interest_rates.to,
        	interest_rates.minimal_rate,
        	interest_rates.served_rate,
        	interest_rates.year_length,
        	(COALESCE(interest_rates.served_rate, interest_rates.minimal_rate) * (1 - interest_rates.social_tax_rate))::numeric(15,10) AS rate_for_computation
          FROM interest_rates
          LEFT JOIN t_euro_funds ON t_euro_funds.id = interest_rates.object_id AND interest_rates.object_type = 'EuroFund'
        ),
        t_interest_rates_filled AS (
          SELECT *
          FROM t_interest_rates
          UNION (
            SELECT
        	t_interest_rates.euro_fund_id,
        	(t_interest_rates.from + '1 year'::interval)::date AS from,
        	(t_interest_rates.to + '1 year'::interval)::date AS to,
        	t_interest_rates.minimal_rate,
        	t_interest_rates.served_rate,
        	(t_interest_rates.to + '1 year'::interval)::date - (t_interest_rates.from + '1 year'::interval)::date + 1 AS year_length,
        	t_interest_rates.rate_for_computation
            FROM t_interest_rates
            JOIN t_euro_funds ON t_interest_rates.euro_fund_id = t_euro_funds.id AND t_interest_rates.to = t_euro_funds.max_to
          )
        )
        SELECT
        	t_interest_rates_filled.euro_fund_id,
        	date(date_series.date_series) AS date,
        	t_interest_rates_filled.minimal_rate,
        	t_interest_rates_filled.served_rate,
        	t_interest_rates_filled.year_length,
        	t_interest_rates_filled.rate_for_computation
        FROM t_interest_rates_filled
        CROSS JOIN generate_series(t_interest_rates_filled.from, t_interest_rates_filled.to, '1 day'::interval) date_series
        WHERE date_series.date_series <= date(transaction_timestamp()::date + '30 days'::interval)
        ORDER BY euro_fund_id, date
    )
    execute 'REFRESH MATERIALIZED VIEW matview_euro_fund_interest_filled'
  end
  def down
    execute %(
      CREATE OR REPLACE VIEW view_euro_fund_interest_filled AS
       SELECT euro_funds.id AS euro_fund_id,
          date(date_series.date_series) AS date,
          t.minimal_rate,
          t.served_rate,
          t.year_length,
          (COALESCE(t.served_rate, t.minimal_rate) * (1::numeric - t.social_tax_rate))::numeric(15,10) AS rate_for_computation
         FROM generate_series((( SELECT min(interest_rates."from") AS min
                 FROM interest_rates))::timestamp without time zone, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series(date_series)
           CROSS JOIN euro_funds
           LEFT JOIN LATERAL ( SELECT interest_rates.id,
                  interest_rates.object_id,
                  interest_rates.object_type,
                  interest_rates.minimal_rate,
                  interest_rates."from",
                  interest_rates."to",
                  interest_rates.created_at,
                  interest_rates.updated_at,
                  interest_rates.served_rate,
                  interest_rates.social_tax_rate,
                  interest_rates.year_length
                 FROM interest_rates
                WHERE interest_rates."from" <= date_series.date_series AND interest_rates.object_id = euro_funds.id AND interest_rates.object_type::text = 'EuroFund'::text
                ORDER BY interest_rates."to" DESC
               LIMIT 1) t ON true;
    )
    execute 'REFRESH MATERIALIZED VIEW matview_euro_fund_interest_filled'
  end
end
