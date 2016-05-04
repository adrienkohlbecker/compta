class CreateMatviewPortfolioOpcvmFundHistoryEurs < ActiveRecord::Migration
  def up
    execute %(
      CREATE MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur AS (
      SELECT date_series.date, opcvm_funds.id AS fund_id, 'OpcvmFund'::character varying AS fund_type, portfolios.id AS portfolio_id,
             t.shares, t.invested,
             matview_opcvm_quotations_filled_eur.value_original * t.shares AS current_value
      FROM generate_series(
        (SELECT MIN(done_at) FROM matview_portfolio_transactions_with_investment_eur),
        transaction_timestamp()::date + '30 days'::interval,
        '1 day'::interval
      ) date_series
      CROSS JOIN opcvm_funds
      CROSS JOIN portfolios
      LEFT OUTER JOIN LATERAL (

        SELECT fund_id,
               portfolio_id,
               SUM(shares) AS shares,
               SUM(invested_original) AS invested
        FROM matview_portfolio_transactions_with_investment_eur
        WHERE fund_type = 'OpcvmFund'
        AND done_at <= date_series.date
        GROUP BY fund_id, portfolio_id

      ) t ON t.fund_id = opcvm_funds.id AND t.portfolio_id = portfolios.id
      JOIN matview_opcvm_quotations_filled_eur ON opcvm_funds.id = matview_opcvm_quotations_filled_eur.opcvm_fund_id AND matview_opcvm_quotations_filled_eur.date = date_series.date
      );
    )
  end

  def down
    execute 'DROP MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur'
  end
end
