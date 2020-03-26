class UpdatePortfolioThreshold < ActiveRecord::Migration
  def up
    execute %(
      CREATE OR REPLACE VIEW public.view_portfolio_history AS
      SELECT history.date,
         history.fund_id,
         history.fund_type,
         history.portfolio_id,
         (
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::numeric
                 ELSE history.shares
             END)::numeric(15,5) AS shares,
         history.invested_original,
         history.invested_currency,
         history.invested_date,
         (
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::numeric
                 ELSE history.current_value_original
             END)::numeric(15,5) AS current_value_original,
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::character varying
                 ELSE history.current_value_currency
             END AS current_value_currency,
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::date
                 ELSE history.current_value_date
             END AS current_value_date,
         (
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN (- history.invested_original)
                 ELSE (history.current_value_original - history.invested_original)
             END)::numeric(15,5) AS pv_original,
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::character varying
                 ELSE history.current_value_currency
             END AS pv_currency,
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::date
                 ELSE history.current_value_date
             END AS pv_date,
         (
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::numeric
                 ELSE history.shareprice_original
             END)::numeric(15,5) AS shareprice_original,
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::character varying
                 ELSE history.shareprice_currency
             END AS shareprice_currency,
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::date
                 ELSE history.shareprice_date
             END AS shareprice_date,
         (
             CASE
                 WHEN (abs(history.shares) < 0.1) THEN NULL::numeric
                 WHEN (history.invested_original = (0)::numeric) THEN NULL::numeric
                 ELSE ((history.current_value_original / history.invested_original) - (1)::numeric)
             END)::numeric(15,5) AS percent
        FROM ( SELECT matview_portfolio_euro_fund_history_eur.date,
                 matview_portfolio_euro_fund_history_eur.fund_id,
                 matview_portfolio_euro_fund_history_eur.fund_type,
                 matview_portfolio_euro_fund_history_eur.portfolio_id,
                 matview_portfolio_euro_fund_history_eur.shares,
                 matview_portfolio_euro_fund_history_eur.invested_original,
                 matview_portfolio_euro_fund_history_eur.invested_currency,
                 matview_portfolio_euro_fund_history_eur.invested_date,
                 matview_portfolio_euro_fund_history_eur.current_value_original,
                 matview_portfolio_euro_fund_history_eur.current_value_currency,
                 matview_portfolio_euro_fund_history_eur.current_value_date,
                 matview_portfolio_euro_fund_history_eur.shareprice_original,
                 matview_portfolio_euro_fund_history_eur.shareprice_currency,
                 matview_portfolio_euro_fund_history_eur.shareprice_date
                FROM public.matview_portfolio_euro_fund_history_eur
             UNION
              SELECT matview_portfolio_opcvm_fund_history_eur.date,
                 matview_portfolio_opcvm_fund_history_eur.fund_id,
                 matview_portfolio_opcvm_fund_history_eur.fund_type,
                 matview_portfolio_opcvm_fund_history_eur.portfolio_id,
                 matview_portfolio_opcvm_fund_history_eur.shares,
                 matview_portfolio_opcvm_fund_history_eur.invested_original,
                 matview_portfolio_opcvm_fund_history_eur.invested_currency,
                 matview_portfolio_opcvm_fund_history_eur.invested_date,
                 matview_portfolio_opcvm_fund_history_eur.current_value_original,
                 matview_portfolio_opcvm_fund_history_eur.current_value_currency,
                 matview_portfolio_opcvm_fund_history_eur.current_value_date,
                 matview_portfolio_opcvm_fund_history_eur.shareprice_original,
                 matview_portfolio_opcvm_fund_history_eur.shareprice_currency,
                 matview_portfolio_opcvm_fund_history_eur.shareprice_date
                FROM public.matview_portfolio_opcvm_fund_history_eur
             UNION
              SELECT matview_portfolio_scpi_fund_history_eur.date,
                 matview_portfolio_scpi_fund_history_eur.fund_id,
                 matview_portfolio_scpi_fund_history_eur.fund_type,
                 matview_portfolio_scpi_fund_history_eur.portfolio_id,
                 matview_portfolio_scpi_fund_history_eur.shares,
                 matview_portfolio_scpi_fund_history_eur.invested_original,
                 matview_portfolio_scpi_fund_history_eur.invested_currency,
                 matview_portfolio_scpi_fund_history_eur.invested_date,
                 matview_portfolio_scpi_fund_history_eur.current_value_original,
                 matview_portfolio_scpi_fund_history_eur.current_value_currency,
                 matview_portfolio_scpi_fund_history_eur.current_value_date,
                 matview_portfolio_scpi_fund_history_eur.shareprice_original,
                 matview_portfolio_scpi_fund_history_eur.shareprice_currency,
                 matview_portfolio_scpi_fund_history_eur.shareprice_date
                FROM public.matview_portfolio_scpi_fund_history_eur) history
       ORDER BY history.date, history.portfolio_id, history.fund_type, history.fund_id;
    )
  end

  def down
    execute %(
      CREATE OR REPLACE VIEW public.view_portfolio_history AS
      SELECT history.date,
          history.fund_id,
          history.fund_type,
          history.portfolio_id,
          (
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  ELSE history.shares
              END)::numeric(15,5) AS shares,
          history.invested_original,
          history.invested_currency,
          history.invested_date,
          (
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  ELSE history.current_value_original
              END)::numeric(15,5) AS current_value_original,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::character varying
                  ELSE history.current_value_currency
              END AS current_value_currency,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::date
                  ELSE history.current_value_date
              END AS current_value_date,
          (
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN (- history.invested_original)
                  ELSE (history.current_value_original - history.invested_original)
              END)::numeric(15,5) AS pv_original,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::character varying
                  ELSE history.current_value_currency
              END AS pv_currency,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::date
                  ELSE history.current_value_date
              END AS pv_date,
          (
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  ELSE history.shareprice_original
              END)::numeric(15,5) AS shareprice_original,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::character varying
                  ELSE history.shareprice_currency
              END AS shareprice_currency,
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::date
                  ELSE history.shareprice_date
              END AS shareprice_date,
          (
              CASE
                  WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
                  WHEN (history.invested_original = (0)::numeric) THEN NULL::numeric
                  ELSE ((history.current_value_original / history.invested_original) - (1)::numeric)
              END)::numeric(15,5) AS percent
        FROM ( SELECT matview_portfolio_euro_fund_history_eur.date,
                  matview_portfolio_euro_fund_history_eur.fund_id,
                  matview_portfolio_euro_fund_history_eur.fund_type,
                  matview_portfolio_euro_fund_history_eur.portfolio_id,
                  matview_portfolio_euro_fund_history_eur.shares,
                  matview_portfolio_euro_fund_history_eur.invested_original,
                  matview_portfolio_euro_fund_history_eur.invested_currency,
                  matview_portfolio_euro_fund_history_eur.invested_date,
                  matview_portfolio_euro_fund_history_eur.current_value_original,
                  matview_portfolio_euro_fund_history_eur.current_value_currency,
                  matview_portfolio_euro_fund_history_eur.current_value_date,
                  matview_portfolio_euro_fund_history_eur.shareprice_original,
                  matview_portfolio_euro_fund_history_eur.shareprice_currency,
                  matview_portfolio_euro_fund_history_eur.shareprice_date
                FROM public.matview_portfolio_euro_fund_history_eur
              UNION
              SELECT matview_portfolio_opcvm_fund_history_eur.date,
                  matview_portfolio_opcvm_fund_history_eur.fund_id,
                  matview_portfolio_opcvm_fund_history_eur.fund_type,
                  matview_portfolio_opcvm_fund_history_eur.portfolio_id,
                  matview_portfolio_opcvm_fund_history_eur.shares,
                  matview_portfolio_opcvm_fund_history_eur.invested_original,
                  matview_portfolio_opcvm_fund_history_eur.invested_currency,
                  matview_portfolio_opcvm_fund_history_eur.invested_date,
                  matview_portfolio_opcvm_fund_history_eur.current_value_original,
                  matview_portfolio_opcvm_fund_history_eur.current_value_currency,
                  matview_portfolio_opcvm_fund_history_eur.current_value_date,
                  matview_portfolio_opcvm_fund_history_eur.shareprice_original,
                  matview_portfolio_opcvm_fund_history_eur.shareprice_currency,
                  matview_portfolio_opcvm_fund_history_eur.shareprice_date
                FROM public.matview_portfolio_opcvm_fund_history_eur
              UNION
              SELECT matview_portfolio_scpi_fund_history_eur.date,
                  matview_portfolio_scpi_fund_history_eur.fund_id,
                  matview_portfolio_scpi_fund_history_eur.fund_type,
                  matview_portfolio_scpi_fund_history_eur.portfolio_id,
                  matview_portfolio_scpi_fund_history_eur.shares,
                  matview_portfolio_scpi_fund_history_eur.invested_original,
                  matview_portfolio_scpi_fund_history_eur.invested_currency,
                  matview_portfolio_scpi_fund_history_eur.invested_date,
                  matview_portfolio_scpi_fund_history_eur.current_value_original,
                  matview_portfolio_scpi_fund_history_eur.current_value_currency,
                  matview_portfolio_scpi_fund_history_eur.current_value_date,
                  matview_portfolio_scpi_fund_history_eur.shareprice_original,
                  matview_portfolio_scpi_fund_history_eur.shareprice_currency,
                  matview_portfolio_scpi_fund_history_eur.shareprice_date
                FROM public.matview_portfolio_scpi_fund_history_eur) history
        ORDER BY history.date, history.portfolio_id, history.fund_type, history.fund_id;
    )
  end
end
