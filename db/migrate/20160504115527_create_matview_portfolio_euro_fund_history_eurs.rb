class CreateMatviewPortfolioEuroFundHistoryEurs < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur AS (
      SELECT date_series.date, euro_funds.id AS fund_id, 'EuroFund'::character varying AS fund_type, portfolios.id AS portfolio_id,
             NULL::numeric(15,5) AS shares,
             invested.invested,
             invested.invested + COALESCE(actual_pv.actual_pv, 0) + COALESCE(latent_pv_this_year.latent_pv_this_year, 0) + COALESCE(latent_pv_last_year.latent_pv_last_year, 0) AS current_value
      FROM generate_series(
        (SELECT MIN(done_at) FROM matview_portfolio_transactions_with_investment_eur),
        transaction_timestamp()::date + '30 days'::interval,
        '1 day'::interval
      ) date_series
      CROSS JOIN euro_funds
      CROSS JOIN portfolios
      LEFT OUTER JOIN LATERAL (
        SELECT rate_for_computation, year_length
        FROM matview_euro_fund_interest_filled
        WHERE matview_euro_fund_interest_filled.euro_fund_id = euro_funds.id
        AND matview_euro_fund_interest_filled.date = date_series.date
      ) interest_rate ON TRUE
      LEFT OUTER JOIN LATERAL (
        SELECT SUM(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
        FROM matview_portfolio_transactions_with_investment_eur
        WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type = 'EuroFund' AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id
        AND matview_portfolio_transactions_with_investment_eur.done_at <= date_series.date
      ) invested ON TRUE
      LEFT OUTER JOIN LATERAL (
        SELECT SUM(matview_portfolio_transactions_with_investment_eur.amount_original) AS actual_pv
        FROM matview_portfolio_transactions_with_investment_eur
        WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type = 'EuroFund' AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id
        AND matview_portfolio_transactions_with_investment_eur.done_at < date_series.date
        AND matview_portfolio_transactions_with_investment_eur.category != 'Virement' AND matview_portfolio_transactions_with_investment_eur.category != 'Arbitrage'
      ) actual_pv ON TRUE
      LEFT OUTER JOIN LATERAL (
        SELECT SUM(matview_portfolio_transactions_with_investment_eur.amount_original * ((1 + interest_rate.rate_for_computation) ^ ((date_series.date - matview_portfolio_transactions_with_investment_eur.done_at) / interest_rate.year_length::numeric) - 1)) AS latent_pv_this_year
        FROM matview_portfolio_transactions_with_investment_eur
        WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type = 'EuroFund' AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id
        AND matview_portfolio_transactions_with_investment_eur.done_at >= date_trunc('year', date_series.date)::date
        AND matview_portfolio_transactions_with_investment_eur.done_at <= date_series.date
      ) latent_pv_this_year ON TRUE
      LEFT OUTER JOIN LATERAL (
        SELECT SUM(matview_portfolio_transactions_with_investment_eur.amount_original) * (((1 + interest_rate.rate_for_computation) ^ ((date_series.date - date_trunc('year', date_series.date)::date + 1 ) / interest_rate.year_length::numeric) - 1)) AS latent_pv_last_year
        FROM matview_portfolio_transactions_with_investment_eur
        WHERE matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id AND matview_portfolio_transactions_with_investment_eur.fund_type = 'EuroFund' AND matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id
        AND matview_portfolio_transactions_with_investment_eur.done_at < date_trunc('year', date_series.date)::date
      ) latent_pv_last_year ON TRUE
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur'
  end
end
