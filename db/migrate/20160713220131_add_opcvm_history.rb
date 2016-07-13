class AddOpcvmHistory < ActiveRecord::Migration
  def up
    execute %(CREATE OR REPLACE VIEW view_portfolio_opcvm_fund_history_eur AS
    SELECT date(date_series.date_series) AS date,
      opcvm_funds.id AS fund_id,
      'OpcvmFund'::character varying AS fund_type,
      portfolios.id AS portfolio_id,
      t.shares::numeric(15,5),
      t.invested::numeric(15,5) AS invested_original,
      'EUR'::character varying AS invested_currency,
      date(date_series.date_series) AS invested_date,
      (matview_opcvm_quotations_filled_eur.value_original * t.shares)::numeric(15,5) AS current_value_original,
      'EUR'::character varying AS current_value_currency,
      date(date_series.date_series) AS current_value_date,
      matview_opcvm_quotations_filled_eur.value_original AS shareprice_original,
      'EUR'::character varying AS shareprice_currency,
      date(date_series.date_series) AS shareprice_date
     FROM generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
             FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, transaction_timestamp()::date + '30 days'::interval, '1 day'::interval) date_series(date_series)
       CROSS JOIN opcvm_funds
       CROSS JOIN portfolios
       JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
              matview_portfolio_transactions_with_investment_eur.portfolio_id,
              sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
              sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
             FROM matview_portfolio_transactions_with_investment_eur
            WHERE matview_portfolio_transactions_with_investment_eur.fund_type::text = 'OpcvmFund'::text AND matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)
            GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON t.fund_id = opcvm_funds.id AND t.portfolio_id = portfolios.id
       JOIN matview_opcvm_quotations_filled_eur ON opcvm_funds.id = matview_opcvm_quotations_filled_eur.opcvm_fund_id AND matview_opcvm_quotations_filled_eur.date = date(date_series.date_series)
       ORDER BY date, portfolio_id, fund_id
    )
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_history'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_performance'
  end
  def down
    execute %(
      CREATE OR REPLACE VIEW view_portfolio_opcvm_fund_history_eur AS
       SELECT date(date_series.date_series) AS date,
          opcvm_funds.id AS fund_id,
          'OpcvmFund'::character varying AS fund_type,
          portfolios.id AS portfolio_id,
          t.shares::numeric(15,5),
          t.invested::numeric(15,5) AS invested_original,
          NULL::character varying AS invested_currency,
          NULL::date AS invested_date,
          (matview_opcvm_quotations_filled_eur.value_original * t.shares)::numeric(15,5) AS current_value_original,
          NULL::character varying AS current_value_currency,
          NULL::date AS current_value_date,
          NULL::numeric(15,5) AS shareprice_original,
          NULL::character varying AS shareprice_currency,
          NULL::date AS shareprice_date
         FROM ((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
                 FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
           CROSS JOIN opcvm_funds)
           CROSS JOIN portfolios)
           LEFT JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
                  matview_portfolio_transactions_with_investment_eur.portfolio_id,
                  sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
                  sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
                 FROM matview_portfolio_transactions_with_investment_eur
                WHERE (((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'OpcvmFund'::text) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))
                GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON (((t.fund_id = opcvm_funds.id) AND (t.portfolio_id = portfolios.id))))
           JOIN matview_opcvm_quotations_filled_eur ON (((opcvm_funds.id = matview_opcvm_quotations_filled_eur.opcvm_fund_id) AND (matview_opcvm_quotations_filled_eur.date = date(date_series.date_series)))));
    )
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_history'
    execute 'REFRESH MATERIALIZED VIEW matview_portfolio_performance'
  end
end
