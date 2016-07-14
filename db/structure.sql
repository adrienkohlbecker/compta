--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE currencies (
    id integer NOT NULL,
    name character varying,
    boursorama_id character varying,
    url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    bf_id character varying
);


--
-- Name: currencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE currencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE currencies_id_seq OWNED BY currencies.id;


--
-- Name: currency_quotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE currency_quotations (
    id integer NOT NULL,
    currency_id integer,
    date date,
    value numeric(15,5),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: currency_cotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE currency_cotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_cotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE currency_cotations_id_seq OWNED BY currency_quotations.id;


--
-- Name: euro_funds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE euro_funds (
    id integer NOT NULL,
    name character varying,
    currency character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: euro_funds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE euro_funds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: euro_funds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE euro_funds_id_seq OWNED BY euro_funds.id;


--
-- Name: opcvm_quotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE opcvm_quotations (
    id integer NOT NULL,
    opcvm_fund_id integer,
    value_original numeric(15,5),
    date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    value_currency character varying,
    value_date date
);


--
-- Name: fund_cotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE fund_cotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fund_cotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fund_cotations_id_seq OWNED BY opcvm_quotations.id;


--
-- Name: interest_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE interest_rates (
    id integer NOT NULL,
    object_id integer,
    object_type character varying,
    minimal_rate numeric(15,5),
    "from" date,
    "to" date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    served_rate numeric(15,5),
    social_tax_rate numeric(15,5),
    year_length integer
);


--
-- Name: interest_rates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE interest_rates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: interest_rates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE interest_rates_id_seq OWNED BY interest_rates.id;


--
-- Name: view_eur_to_currency; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_eur_to_currency AS
 WITH t_currencies_tmp AS (
         SELECT currencies.id,
            currencies.name,
            min(currency_quotations.date) AS min,
            max(currency_quotations.date) AS max
           FROM (currencies
             JOIN currency_quotations ON ((currency_quotations.currency_id = currencies.id)))
          GROUP BY currencies.id, currencies.name
        ), t_currencies AS (
         SELECT t_currencies_tmp.id,
            t_currencies_tmp.name,
            t_currencies_tmp.min,
            t_currencies_tmp.max,
            currency_quotations.value AS value_at_max_date
           FROM (t_currencies_tmp
             JOIN currency_quotations ON ((currency_quotations.currency_id = t_currencies_tmp.id)))
          WHERE (currency_quotations.date = t_currencies_tmp.max)
        )
 SELECT t_currencies.id AS currency_id,
    t_currencies.name AS currency_name,
    date(date_series.date_series) AS date,
    t_values.value
   FROM ((t_currencies
     CROSS JOIN LATERAL generate_series((t_currencies.min)::timestamp with time zone, (t_currencies.max)::timestamp with time zone, '1 day'::interval) date_series(date_series))
     JOIN LATERAL ( SELECT currency_quotations.value
           FROM currency_quotations
          WHERE ((currency_quotations.currency_id = t_currencies.id) AND (currency_quotations.date >= date_series.date_series))
          ORDER BY currency_quotations.date
         LIMIT 1) t_values ON (true))
UNION
 SELECT t_currencies.id AS currency_id,
    t_currencies.name AS currency_name,
    date(date_series.date_series) AS date,
    t_currencies.value_at_max_date AS value
   FROM (t_currencies
     CROSS JOIN LATERAL generate_series((t_currencies.max + '1 day'::interval), ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series))
  ORDER BY 1, 3;


--
-- Name: matview_eur_to_currency; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_eur_to_currency AS
 SELECT view_eur_to_currency.currency_id,
    view_eur_to_currency.currency_name,
    view_eur_to_currency.date,
    view_eur_to_currency.value
   FROM view_eur_to_currency
  WITH NO DATA;


--
-- Name: view_euro_fund_interest_filled; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_euro_fund_interest_filled AS
 WITH t_euro_funds AS (
         SELECT euro_funds.id,
            max(interest_rates."to") AS max_to
           FROM (euro_funds
             JOIN interest_rates ON (((interest_rates.object_id = euro_funds.id) AND ((interest_rates.object_type)::text = 'EuroFund'::text))))
          GROUP BY euro_funds.id
        ), t_interest_rates AS (
         SELECT t_euro_funds.id AS euro_fund_id,
            interest_rates."from",
            interest_rates."to",
            interest_rates.minimal_rate,
            interest_rates.served_rate,
            interest_rates.year_length,
            ((COALESCE(interest_rates.served_rate, interest_rates.minimal_rate) * ((1)::numeric - interest_rates.social_tax_rate)))::numeric(15,10) AS rate_for_computation
           FROM (interest_rates
             LEFT JOIN t_euro_funds ON (((t_euro_funds.id = interest_rates.object_id) AND ((interest_rates.object_type)::text = 'EuroFund'::text))))
        ), t_interest_rates_filled AS (
         SELECT t_interest_rates.euro_fund_id,
            t_interest_rates."from",
            t_interest_rates."to",
            t_interest_rates.minimal_rate,
            t_interest_rates.served_rate,
            t_interest_rates.year_length,
            t_interest_rates.rate_for_computation
           FROM t_interest_rates
        UNION
         SELECT t_interest_rates.euro_fund_id,
            ((t_interest_rates."from" + '1 year'::interval))::date AS "from",
            ((t_interest_rates."to" + '1 year'::interval))::date AS "to",
            t_interest_rates.minimal_rate,
            t_interest_rates.served_rate,
            ((((t_interest_rates."to" + '1 year'::interval))::date - ((t_interest_rates."from" + '1 year'::interval))::date) + 1) AS year_length,
            t_interest_rates.rate_for_computation
           FROM (t_interest_rates
             JOIN t_euro_funds ON (((t_interest_rates.euro_fund_id = t_euro_funds.id) AND (t_interest_rates."to" = t_euro_funds.max_to))))
        )
 SELECT t_interest_rates_filled.euro_fund_id,
    date(date_series.date_series) AS date,
    t_interest_rates_filled.minimal_rate,
    t_interest_rates_filled.served_rate,
    t_interest_rates_filled.year_length,
    t_interest_rates_filled.rate_for_computation
   FROM (t_interest_rates_filled
     CROSS JOIN LATERAL generate_series((t_interest_rates_filled."from")::timestamp with time zone, (t_interest_rates_filled."to")::timestamp with time zone, '1 day'::interval) date_series(date_series))
  WHERE (date_series.date_series <= date(((transaction_timestamp())::date + '30 days'::interval)))
  ORDER BY t_interest_rates_filled.euro_fund_id, (date(date_series.date_series));


--
-- Name: matview_euro_fund_interest_filled; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_euro_fund_interest_filled AS
 SELECT view_euro_fund_interest_filled.euro_fund_id,
    view_euro_fund_interest_filled.date,
    view_euro_fund_interest_filled.minimal_rate,
    view_euro_fund_interest_filled.served_rate,
    view_euro_fund_interest_filled.year_length,
    view_euro_fund_interest_filled.rate_for_computation
   FROM view_euro_fund_interest_filled
  WITH NO DATA;


--
-- Name: view_opcvm_quotations_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_opcvm_quotations_eur AS
 SELECT opcvm_quotations.opcvm_fund_id,
    opcvm_quotations.date,
    (
        CASE
            WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN opcvm_quotations.value_original
            ELSE (opcvm_quotations.value_original / matview_eur_to_currency.value)
        END)::numeric(15,5) AS value_original,
    'EUR'::character varying AS value_currency,
    opcvm_quotations.value_date,
        CASE
            WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN NULL::numeric(15,5)
            ELSE opcvm_quotations.value_original
        END AS original_value_original,
        CASE
            WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN NULL::character varying
            ELSE opcvm_quotations.value_currency
        END AS original_value_currency,
        CASE
            WHEN ((opcvm_quotations.value_currency)::text = 'EUR'::text) THEN NULL::date
            ELSE opcvm_quotations.value_date
        END AS original_value_date
   FROM (opcvm_quotations
     LEFT JOIN matview_eur_to_currency ON (((opcvm_quotations.value_date = matview_eur_to_currency.date) AND ((opcvm_quotations.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
  ORDER BY opcvm_quotations.opcvm_fund_id, opcvm_quotations.date;


--
-- Name: matview_opcvm_quotations_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_opcvm_quotations_eur AS
 SELECT view_opcvm_quotations_eur.opcvm_fund_id,
    view_opcvm_quotations_eur.date,
    view_opcvm_quotations_eur.value_original,
    view_opcvm_quotations_eur.value_currency,
    view_opcvm_quotations_eur.value_date,
    view_opcvm_quotations_eur.original_value_original,
    view_opcvm_quotations_eur.original_value_currency,
    view_opcvm_quotations_eur.original_value_date
   FROM view_opcvm_quotations_eur
  WITH NO DATA;


--
-- Name: opcvm_funds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE opcvm_funds (
    id integer NOT NULL,
    isin character varying,
    name character varying,
    boursorama_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    currency character varying,
    closed boolean DEFAULT false NOT NULL,
    closed_date date
);


--
-- Name: view_opcvm_quotations_filled_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_opcvm_quotations_filled_eur AS
 WITH t_opcvm_funds AS (
         SELECT opcvm_funds.id,
            min(matview_opcvm_quotations_eur.date) AS min_quotation,
            max(matview_opcvm_quotations_eur.date) AS max_quotation
           FROM (opcvm_funds
             JOIN matview_opcvm_quotations_eur ON ((matview_opcvm_quotations_eur.opcvm_fund_id = opcvm_funds.id)))
          GROUP BY opcvm_funds.id
        )
 SELECT t_opcvm_funds.id AS opcvm_fund_id,
    date(date_series.date_series) AS date,
    t_values.value_original,
    t_values.value_currency,
    t_values.value_date,
    t_values.original_value_original,
    t_values.original_value_currency,
    t_values.original_value_date
   FROM ((t_opcvm_funds
     CROSS JOIN LATERAL generate_series((t_opcvm_funds.min_quotation)::timestamp with time zone, (t_opcvm_funds.max_quotation)::timestamp with time zone, '1 day'::interval) date_series(date_series))
     JOIN LATERAL ( SELECT matview_opcvm_quotations_eur.opcvm_fund_id,
            matview_opcvm_quotations_eur.date,
            matview_opcvm_quotations_eur.value_original,
            matview_opcvm_quotations_eur.value_currency,
            matview_opcvm_quotations_eur.value_date,
            matview_opcvm_quotations_eur.original_value_original,
            matview_opcvm_quotations_eur.original_value_currency,
            matview_opcvm_quotations_eur.original_value_date
           FROM matview_opcvm_quotations_eur
          WHERE ((matview_opcvm_quotations_eur.opcvm_fund_id = t_opcvm_funds.id) AND (matview_opcvm_quotations_eur.date >= date_series.date_series))
          ORDER BY matview_opcvm_quotations_eur.date
         LIMIT 1) t_values ON (true))
UNION
 SELECT t_opcvm_funds.id AS opcvm_fund_id,
    date(date_series.date_series) AS date,
    t_values.value_original,
    t_values.value_currency,
    t_values.value_date,
    t_values.original_value_original,
    t_values.original_value_currency,
    t_values.original_value_date
   FROM ((t_opcvm_funds
     CROSS JOIN LATERAL generate_series((t_opcvm_funds.max_quotation + '1 day'::interval), ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series))
     LEFT JOIN matview_opcvm_quotations_eur t_values ON (((t_values.opcvm_fund_id = t_opcvm_funds.id) AND (t_values.date = t_opcvm_funds.max_quotation))))
  ORDER BY 1, 2;


--
-- Name: matview_opcvm_quotations_filled_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled_eur AS
 SELECT view_opcvm_quotations_filled_eur.opcvm_fund_id,
    view_opcvm_quotations_filled_eur.date,
    view_opcvm_quotations_filled_eur.value_original,
    view_opcvm_quotations_filled_eur.value_currency,
    view_opcvm_quotations_filled_eur.value_date,
    view_opcvm_quotations_filled_eur.original_value_original,
    view_opcvm_quotations_filled_eur.original_value_currency,
    view_opcvm_quotations_filled_eur.original_value_date
   FROM view_opcvm_quotations_filled_eur
  WITH NO DATA;


--
-- Name: portfolio_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE portfolio_transactions (
    id integer NOT NULL,
    fund_id integer,
    shares numeric(15,5),
    portfolio_id integer,
    done_at date,
    amount_original numeric(15,5),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    amount_currency character varying,
    amount_date date,
    fund_type character varying,
    category character varying,
    shareprice_original numeric(15,5),
    shareprice_date date,
    shareprice_currency character varying
);


--
-- Name: view_portfolio_transactions_with_investment; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_portfolio_transactions_with_investment AS
 SELECT portfolio_transactions.id,
    portfolio_transactions.fund_id,
    portfolio_transactions.shares,
    portfolio_transactions.portfolio_id,
    portfolio_transactions.done_at,
    portfolio_transactions.fund_type,
    portfolio_transactions.category,
    portfolio_transactions.amount_original,
    portfolio_transactions.amount_currency,
    portfolio_transactions.amount_date,
    portfolio_transactions.shareprice_original,
    portfolio_transactions.shareprice_currency,
    portfolio_transactions.shareprice_date,
    (
        CASE
            WHEN (((portfolio_transactions.category)::text = 'Virement'::text) OR ((portfolio_transactions.category)::text = 'Arbitrage'::text)) THEN portfolio_transactions.amount_original
            ELSE (0)::numeric
        END)::numeric(15,5) AS invested_original,
    portfolio_transactions.amount_currency AS invested_currency,
    portfolio_transactions.amount_date AS invested_date
   FROM portfolio_transactions
  ORDER BY portfolio_transactions.done_at, portfolio_transactions.portfolio_id, portfolio_transactions.fund_type, portfolio_transactions.fund_id;


--
-- Name: view_portfolio_transactions_with_investment_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_portfolio_transactions_with_investment_eur AS
 SELECT view_portfolio_transactions_with_investment.id,
    view_portfolio_transactions_with_investment.fund_id,
    view_portfolio_transactions_with_investment.shares,
    view_portfolio_transactions_with_investment.portfolio_id,
    view_portfolio_transactions_with_investment.done_at,
    view_portfolio_transactions_with_investment.fund_type,
    view_portfolio_transactions_with_investment.category,
    (
        CASE
            WHEN ((view_portfolio_transactions_with_investment.amount_currency)::text = 'EUR'::text) THEN view_portfolio_transactions_with_investment.amount_original
            ELSE (view_portfolio_transactions_with_investment.amount_original / matview_eur_to_currency_for_amount.value)
        END)::numeric(15,5) AS amount_original,
    'EUR'::character varying AS amount_currency,
    view_portfolio_transactions_with_investment.amount_date,
    (
        CASE
            WHEN ((view_portfolio_transactions_with_investment.shareprice_currency)::text = 'EUR'::text) THEN view_portfolio_transactions_with_investment.shareprice_original
            ELSE (view_portfolio_transactions_with_investment.shareprice_original / matview_eur_to_currency_for_shareprice.value)
        END)::numeric(15,5) AS shareprice_original,
    'EUR'::character varying AS shareprice_currency,
    view_portfolio_transactions_with_investment.shareprice_date,
    (
        CASE
            WHEN ((view_portfolio_transactions_with_investment.invested_currency)::text = 'EUR'::text) THEN view_portfolio_transactions_with_investment.invested_original
            ELSE (view_portfolio_transactions_with_investment.invested_original / matview_eur_to_currency_for_amount.value)
        END)::numeric(15,5) AS invested_original,
    'EUR'::character varying AS invested_currency,
    view_portfolio_transactions_with_investment.invested_date
   FROM (((view_portfolio_transactions_with_investment
     LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_amount ON (((view_portfolio_transactions_with_investment.amount_date = matview_eur_to_currency_for_amount.date) AND ((view_portfolio_transactions_with_investment.amount_currency)::text = (matview_eur_to_currency_for_amount.currency_name)::text))))
     LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_shareprice ON (((view_portfolio_transactions_with_investment.amount_date = matview_eur_to_currency_for_shareprice.date) AND ((view_portfolio_transactions_with_investment.amount_currency)::text = (matview_eur_to_currency_for_shareprice.currency_name)::text))))
     LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_invested ON (((view_portfolio_transactions_with_investment.amount_date = matview_eur_to_currency_for_invested.date) AND ((view_portfolio_transactions_with_investment.amount_currency)::text = (matview_eur_to_currency_for_invested.currency_name)::text))))
  ORDER BY view_portfolio_transactions_with_investment.done_at, view_portfolio_transactions_with_investment.portfolio_id, view_portfolio_transactions_with_investment.fund_type, view_portfolio_transactions_with_investment.fund_id;


--
-- Name: matview_portfolio_transactions_with_investment_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur AS
 SELECT view_portfolio_transactions_with_investment_eur.id,
    view_portfolio_transactions_with_investment_eur.fund_id,
    view_portfolio_transactions_with_investment_eur.shares,
    view_portfolio_transactions_with_investment_eur.portfolio_id,
    view_portfolio_transactions_with_investment_eur.done_at,
    view_portfolio_transactions_with_investment_eur.fund_type,
    view_portfolio_transactions_with_investment_eur.category,
    view_portfolio_transactions_with_investment_eur.amount_original,
    view_portfolio_transactions_with_investment_eur.amount_currency,
    view_portfolio_transactions_with_investment_eur.amount_date,
    view_portfolio_transactions_with_investment_eur.shareprice_original,
    view_portfolio_transactions_with_investment_eur.shareprice_currency,
    view_portfolio_transactions_with_investment_eur.shareprice_date,
    view_portfolio_transactions_with_investment_eur.invested_original,
    view_portfolio_transactions_with_investment_eur.invested_currency,
    view_portfolio_transactions_with_investment_eur.invested_date
   FROM view_portfolio_transactions_with_investment_eur
  WITH NO DATA;


--
-- Name: portfolios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE portfolios (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: view_portfolio_euro_fund_history_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_portfolio_euro_fund_history_eur AS
 SELECT date(date_series.date_series) AS date,
    euro_funds.id AS fund_id,
    'EuroFund'::character varying AS fund_type,
    portfolios.id AS portfolio_id,
    NULL::numeric(15,5) AS shares,
    (invested.invested)::numeric(15,5) AS invested_original,
    'EUR'::character varying AS invested_currency,
    date(date_series.date_series) AS invested_date,
    ((((invested.invested + COALESCE(actual_pv.actual_pv, (0)::numeric)) + COALESCE(latent_pv_this_year.latent_pv_this_year, (0)::numeric)) + COALESCE(latent_pv_last_year.latent_pv_last_year, (0)::numeric)))::numeric(15,5) AS current_value_original,
    'EUR'::character varying AS current_value_currency,
    date(date_series.date_series) AS current_value_date,
    NULL::numeric(15,5) AS shareprice_original,
    NULL::character varying AS shareprice_currency,
    NULL::date AS shareprice_date
   FROM (((((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
           FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
     CROSS JOIN euro_funds)
     CROSS JOIN portfolios)
     LEFT JOIN LATERAL ( SELECT matview_euro_fund_interest_filled.rate_for_computation,
            matview_euro_fund_interest_filled.year_length
           FROM matview_euro_fund_interest_filled
          WHERE ((matview_euro_fund_interest_filled.euro_fund_id = euro_funds.id) AND (matview_euro_fund_interest_filled.date = date(date_series.date_series)))) interest_rate ON (true))
     LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))) invested ON (true))
     LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.amount_original) AS actual_pv
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at < date(date_series.date_series)) AND ((matview_portfolio_transactions_with_investment_eur.category)::text <> 'Virement'::text) AND ((matview_portfolio_transactions_with_investment_eur.category)::text <> 'Arbitrage'::text))) actual_pv ON (true))
     LEFT JOIN LATERAL ( SELECT sum((matview_portfolio_transactions_with_investment_eur.amount_original * ((((1)::numeric + interest_rate.rate_for_computation) ^ (((date(date_series.date_series) - matview_portfolio_transactions_with_investment_eur.done_at))::numeric / (interest_rate.year_length)::numeric)) - (1)::numeric))) AS latent_pv_this_year
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at >= (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))) latent_pv_this_year ON (true))
     LEFT JOIN LATERAL ( SELECT (sum(matview_portfolio_transactions_with_investment_eur.amount_original) * ((((1)::numeric + interest_rate.rate_for_computation) ^ ((((date(date_series.date_series) - (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date) + 1))::numeric / (interest_rate.year_length)::numeric)) - (1)::numeric)) AS latent_pv_last_year
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE ((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id) AND (matview_portfolio_transactions_with_investment_eur.done_at < (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date))) latent_pv_last_year ON (true))
  WHERE (invested.invested IS NOT NULL)
  ORDER BY (date(date_series.date_series)), portfolios.id, euro_funds.id;


--
-- Name: matview_portfolio_euro_fund_history_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur AS
 SELECT view_portfolio_euro_fund_history_eur.date,
    view_portfolio_euro_fund_history_eur.fund_id,
    view_portfolio_euro_fund_history_eur.fund_type,
    view_portfolio_euro_fund_history_eur.portfolio_id,
    view_portfolio_euro_fund_history_eur.shares,
    view_portfolio_euro_fund_history_eur.invested_original,
    view_portfolio_euro_fund_history_eur.invested_currency,
    view_portfolio_euro_fund_history_eur.invested_date,
    view_portfolio_euro_fund_history_eur.current_value_original,
    view_portfolio_euro_fund_history_eur.current_value_currency,
    view_portfolio_euro_fund_history_eur.current_value_date,
    view_portfolio_euro_fund_history_eur.shareprice_original,
    view_portfolio_euro_fund_history_eur.shareprice_currency,
    view_portfolio_euro_fund_history_eur.shareprice_date
   FROM view_portfolio_euro_fund_history_eur
  WITH NO DATA;


--
-- Name: view_portfolio_opcvm_fund_history_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_portfolio_opcvm_fund_history_eur AS
 SELECT date(date_series.date_series) AS date,
    opcvm_funds.id AS fund_id,
    'OpcvmFund'::character varying AS fund_type,
    portfolios.id AS portfolio_id,
    (t.shares)::numeric(15,5) AS shares,
    (t.invested)::numeric(15,5) AS invested_original,
    'EUR'::character varying AS invested_currency,
    date(date_series.date_series) AS invested_date,
    ((matview_opcvm_quotations_filled_eur.value_original * t.shares))::numeric(15,5) AS current_value_original,
    'EUR'::character varying AS current_value_currency,
    date(date_series.date_series) AS current_value_date,
    matview_opcvm_quotations_filled_eur.value_original AS shareprice_original,
    'EUR'::character varying AS shareprice_currency,
    date(date_series.date_series) AS shareprice_date
   FROM ((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
           FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
     CROSS JOIN opcvm_funds)
     CROSS JOIN portfolios)
     JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
            matview_portfolio_transactions_with_investment_eur.portfolio_id,
            sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
            sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE (((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'OpcvmFund'::text) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))
          GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON (((t.fund_id = opcvm_funds.id) AND (t.portfolio_id = portfolios.id))))
     JOIN matview_opcvm_quotations_filled_eur ON (((opcvm_funds.id = matview_opcvm_quotations_filled_eur.opcvm_fund_id) AND (matview_opcvm_quotations_filled_eur.date = date(date_series.date_series)))))
  ORDER BY (date(date_series.date_series)), portfolios.id, opcvm_funds.id;


--
-- Name: matview_portfolio_opcvm_fund_history_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur AS
 SELECT view_portfolio_opcvm_fund_history_eur.date,
    view_portfolio_opcvm_fund_history_eur.fund_id,
    view_portfolio_opcvm_fund_history_eur.fund_type,
    view_portfolio_opcvm_fund_history_eur.portfolio_id,
    view_portfolio_opcvm_fund_history_eur.shares,
    view_portfolio_opcvm_fund_history_eur.invested_original,
    view_portfolio_opcvm_fund_history_eur.invested_currency,
    view_portfolio_opcvm_fund_history_eur.invested_date,
    view_portfolio_opcvm_fund_history_eur.current_value_original,
    view_portfolio_opcvm_fund_history_eur.current_value_currency,
    view_portfolio_opcvm_fund_history_eur.current_value_date,
    view_portfolio_opcvm_fund_history_eur.shareprice_original,
    view_portfolio_opcvm_fund_history_eur.shareprice_currency,
    view_portfolio_opcvm_fund_history_eur.shareprice_date
   FROM view_portfolio_opcvm_fund_history_eur
  WITH NO DATA;


--
-- Name: scpi_quotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE scpi_quotations (
    id integer NOT NULL,
    value_original numeric(15,5) NOT NULL,
    value_currency character varying NOT NULL,
    value_date date NOT NULL,
    subscription_value_original numeric(15,5) NOT NULL,
    subscription_value_currency character varying NOT NULL,
    subscription_value_date date NOT NULL,
    date date NOT NULL,
    scpi_fund_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: view_scpi_quotations_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_scpi_quotations_eur AS
 SELECT scpi_quotations.scpi_fund_id,
    scpi_quotations.date,
    (
        CASE
            WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN scpi_quotations.value_original
            ELSE (scpi_quotations.value_original / matview_eur_to_currency.value)
        END)::numeric(15,5) AS value_original,
    'EUR'::character varying AS value_currency,
    scpi_quotations.value_date,
        CASE
            WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN NULL::numeric(15,5)
            ELSE scpi_quotations.value_original
        END AS original_value_original,
        CASE
            WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN NULL::character varying
            ELSE scpi_quotations.value_currency
        END AS original_value_currency,
        CASE
            WHEN ((scpi_quotations.value_currency)::text = 'EUR'::text) THEN NULL::date
            ELSE scpi_quotations.value_date
        END AS original_value_date
   FROM (scpi_quotations
     LEFT JOIN matview_eur_to_currency ON (((scpi_quotations.value_date = matview_eur_to_currency.date) AND ((scpi_quotations.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
  ORDER BY scpi_quotations.scpi_fund_id, scpi_quotations.date;


--
-- Name: matview_scpi_quotations_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_scpi_quotations_eur AS
 SELECT view_scpi_quotations_eur.scpi_fund_id,
    view_scpi_quotations_eur.date,
    view_scpi_quotations_eur.value_original,
    view_scpi_quotations_eur.value_currency,
    view_scpi_quotations_eur.value_date,
    view_scpi_quotations_eur.original_value_original,
    view_scpi_quotations_eur.original_value_currency,
    view_scpi_quotations_eur.original_value_date
   FROM view_scpi_quotations_eur
  WITH NO DATA;


--
-- Name: scpi_funds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE scpi_funds (
    id integer NOT NULL,
    isin character varying NOT NULL,
    name character varying NOT NULL,
    currency character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: view_scpi_quotations_filled_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_scpi_quotations_filled_eur AS
 WITH t_scpi_funds AS (
         SELECT scpi_funds.id,
            min(matview_scpi_quotations_eur.date) AS min_quotation,
            max(matview_scpi_quotations_eur.date) AS max_quotation
           FROM (scpi_funds
             JOIN matview_scpi_quotations_eur ON ((matview_scpi_quotations_eur.scpi_fund_id = scpi_funds.id)))
          GROUP BY scpi_funds.id
        )
 SELECT t_scpi_funds.id AS scpi_fund_id,
    date(date_series.date_series) AS date,
    t_values.value_original,
    t_values.value_currency,
    t_values.value_date,
    t_values.original_value_original,
    t_values.original_value_currency,
    t_values.original_value_date
   FROM ((t_scpi_funds
     CROSS JOIN LATERAL generate_series((t_scpi_funds.min_quotation)::timestamp with time zone, (t_scpi_funds.max_quotation)::timestamp with time zone, '1 day'::interval) date_series(date_series))
     JOIN LATERAL ( SELECT matview_scpi_quotations_eur.scpi_fund_id,
            matview_scpi_quotations_eur.date,
            matview_scpi_quotations_eur.value_original,
            matview_scpi_quotations_eur.value_currency,
            matview_scpi_quotations_eur.value_date,
            matview_scpi_quotations_eur.original_value_original,
            matview_scpi_quotations_eur.original_value_currency,
            matview_scpi_quotations_eur.original_value_date
           FROM matview_scpi_quotations_eur
          WHERE ((matview_scpi_quotations_eur.scpi_fund_id = t_scpi_funds.id) AND (matview_scpi_quotations_eur.date <= date_series.date_series))
          ORDER BY matview_scpi_quotations_eur.date DESC
         LIMIT 1) t_values ON (true))
UNION
 SELECT t_scpi_funds.id AS scpi_fund_id,
    date(date_series.date_series) AS date,
    t_values.value_original,
    t_values.value_currency,
    t_values.value_date,
    t_values.original_value_original,
    t_values.original_value_currency,
    t_values.original_value_date
   FROM ((t_scpi_funds
     CROSS JOIN LATERAL generate_series((t_scpi_funds.max_quotation + '1 day'::interval), ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series))
     LEFT JOIN matview_scpi_quotations_eur t_values ON (((t_values.scpi_fund_id = t_scpi_funds.id) AND (t_values.date = t_scpi_funds.max_quotation))))
  ORDER BY 1, 2;


--
-- Name: matview_scpi_quotations_filled_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_scpi_quotations_filled_eur AS
 SELECT view_scpi_quotations_filled_eur.scpi_fund_id,
    view_scpi_quotations_filled_eur.date,
    view_scpi_quotations_filled_eur.value_original,
    view_scpi_quotations_filled_eur.value_currency,
    view_scpi_quotations_filled_eur.value_date,
    view_scpi_quotations_filled_eur.original_value_original,
    view_scpi_quotations_filled_eur.original_value_currency,
    view_scpi_quotations_filled_eur.original_value_date
   FROM view_scpi_quotations_filled_eur
  WITH NO DATA;


--
-- Name: view_portfolio_scpi_fund_history_eur; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_portfolio_scpi_fund_history_eur AS
 SELECT date(date_series.date_series) AS date,
    scpi_funds.id AS fund_id,
    'ScpiFund'::character varying AS fund_type,
    portfolios.id AS portfolio_id,
    (t.shares)::numeric(15,5) AS shares,
    (t.invested)::numeric(15,5) AS invested_original,
    'EUR'::character varying AS invested_currency,
    date(date_series.date_series) AS invested_date,
    ((matview_scpi_quotations_filled_eur.value_original * t.shares))::numeric(15,5) AS current_value_original,
    'EUR'::character varying AS current_value_currency,
    date(date_series.date_series) AS current_value_date,
    matview_scpi_quotations_filled_eur.value_original AS shareprice_original,
    'EUR'::character varying AS shareprice_currency,
    date(date_series.date_series) AS shareprice_date
   FROM ((((generate_series((( SELECT min(matview_portfolio_transactions_with_investment_eur.done_at) AS min
           FROM matview_portfolio_transactions_with_investment_eur))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
     CROSS JOIN scpi_funds)
     CROSS JOIN portfolios)
     JOIN LATERAL ( SELECT matview_portfolio_transactions_with_investment_eur.fund_id,
            matview_portfolio_transactions_with_investment_eur.portfolio_id,
            sum(matview_portfolio_transactions_with_investment_eur.shares) AS shares,
            sum(matview_portfolio_transactions_with_investment_eur.invested_original) AS invested
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE (((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'ScpiFund'::text) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))
          GROUP BY matview_portfolio_transactions_with_investment_eur.fund_id, matview_portfolio_transactions_with_investment_eur.portfolio_id) t ON (((t.fund_id = scpi_funds.id) AND (t.portfolio_id = portfolios.id))))
     JOIN matview_scpi_quotations_filled_eur ON (((scpi_funds.id = matview_scpi_quotations_filled_eur.scpi_fund_id) AND (matview_scpi_quotations_filled_eur.date = date(date_series.date_series)))))
  ORDER BY (date(date_series.date_series)), portfolios.id, scpi_funds.id;


--
-- Name: matview_portfolio_scpi_fund_history_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_portfolio_scpi_fund_history_eur AS
 SELECT view_portfolio_scpi_fund_history_eur.date,
    view_portfolio_scpi_fund_history_eur.fund_id,
    view_portfolio_scpi_fund_history_eur.fund_type,
    view_portfolio_scpi_fund_history_eur.portfolio_id,
    view_portfolio_scpi_fund_history_eur.shares,
    view_portfolio_scpi_fund_history_eur.invested_original,
    view_portfolio_scpi_fund_history_eur.invested_currency,
    view_portfolio_scpi_fund_history_eur.invested_date,
    view_portfolio_scpi_fund_history_eur.current_value_original,
    view_portfolio_scpi_fund_history_eur.current_value_currency,
    view_portfolio_scpi_fund_history_eur.current_value_date,
    view_portfolio_scpi_fund_history_eur.shareprice_original,
    view_portfolio_scpi_fund_history_eur.shareprice_currency,
    view_portfolio_scpi_fund_history_eur.shareprice_date
   FROM view_portfolio_scpi_fund_history_eur
  WITH NO DATA;


--
-- Name: view_portfolio_history; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_portfolio_history AS
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
           FROM matview_portfolio_euro_fund_history_eur
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
           FROM matview_portfolio_opcvm_fund_history_eur
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
           FROM matview_portfolio_scpi_fund_history_eur) history
  ORDER BY history.date, history.portfolio_id, history.fund_type, history.fund_id;


--
-- Name: matview_portfolio_history; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_portfolio_history AS
 SELECT view_portfolio_history.date,
    view_portfolio_history.fund_id,
    view_portfolio_history.fund_type,
    view_portfolio_history.portfolio_id,
    view_portfolio_history.shares,
    view_portfolio_history.invested_original,
    view_portfolio_history.invested_currency,
    view_portfolio_history.invested_date,
    view_portfolio_history.current_value_original,
    view_portfolio_history.current_value_currency,
    view_portfolio_history.current_value_date,
    view_portfolio_history.pv_original,
    view_portfolio_history.pv_currency,
    view_portfolio_history.pv_date,
    view_portfolio_history.shareprice_original,
    view_portfolio_history.shareprice_currency,
    view_portfolio_history.shareprice_date,
    view_portfolio_history.percent
   FROM view_portfolio_history
  WITH NO DATA;


--
-- Name: view_portfolio_performance; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW view_portfolio_performance AS
 SELECT matview_portfolio_history.date,
    matview_portfolio_history.portfolio_id,
    (sum(matview_portfolio_history.invested_original))::numeric(15,5) AS invested_original,
    'EUR'::character varying AS invested_currency,
    matview_portfolio_history.date AS invested_date,
    (sum(matview_portfolio_history.current_value_original))::numeric(15,5) AS current_value_original,
    'EUR'::character varying AS current_value_currency,
    matview_portfolio_history.date AS current_value_date,
    (sum(matview_portfolio_history.pv_original))::numeric(15,5) AS pv_original,
    'EUR'::character varying AS pv_currency,
    matview_portfolio_history.date AS pv_date
   FROM matview_portfolio_history
  WHERE (matview_portfolio_history.invested_original IS NOT NULL)
  GROUP BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id
  ORDER BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id;


--
-- Name: matview_portfolio_performance; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW matview_portfolio_performance AS
 SELECT view_portfolio_performance.date,
    view_portfolio_performance.portfolio_id,
    view_portfolio_performance.invested_original,
    view_portfolio_performance.invested_currency,
    view_portfolio_performance.invested_date,
    view_portfolio_performance.current_value_original,
    view_portfolio_performance.current_value_currency,
    view_portfolio_performance.current_value_date,
    view_portfolio_performance.pv_original,
    view_portfolio_performance.pv_currency,
    view_portfolio_performance.pv_date
   FROM view_portfolio_performance
  WITH NO DATA;


--
-- Name: opcvm_funds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE opcvm_funds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opcvm_funds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE opcvm_funds_id_seq OWNED BY opcvm_funds.id;


--
-- Name: portfolio_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portfolio_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: portfolio_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portfolio_transactions_id_seq OWNED BY portfolio_transactions.id;


--
-- Name: portfolios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE portfolios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: portfolios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE portfolios_id_seq OWNED BY portfolios.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: scpi_funds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scpi_funds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scpi_funds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scpi_funds_id_seq OWNED BY scpi_funds.id;


--
-- Name: scpi_quotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE scpi_quotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scpi_quotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE scpi_quotations_id_seq OWNED BY scpi_quotations.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY currencies ALTER COLUMN id SET DEFAULT nextval('currencies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY currency_quotations ALTER COLUMN id SET DEFAULT nextval('currency_cotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY euro_funds ALTER COLUMN id SET DEFAULT nextval('euro_funds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY interest_rates ALTER COLUMN id SET DEFAULT nextval('interest_rates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY opcvm_funds ALTER COLUMN id SET DEFAULT nextval('opcvm_funds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY opcvm_quotations ALTER COLUMN id SET DEFAULT nextval('fund_cotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY portfolio_transactions ALTER COLUMN id SET DEFAULT nextval('portfolio_transactions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY portfolios ALTER COLUMN id SET DEFAULT nextval('portfolios_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scpi_funds ALTER COLUMN id SET DEFAULT nextval('scpi_funds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY scpi_quotations ALTER COLUMN id SET DEFAULT nextval('scpi_quotations_id_seq'::regclass);


--
-- Name: currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: currency_quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY currency_quotations
    ADD CONSTRAINT currency_quotations_pkey PRIMARY KEY (id);


--
-- Name: euro_funds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY euro_funds
    ADD CONSTRAINT euro_funds_pkey PRIMARY KEY (id);


--
-- Name: fund_quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY opcvm_quotations
    ADD CONSTRAINT fund_quotations_pkey PRIMARY KEY (id);


--
-- Name: interest_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY interest_rates
    ADD CONSTRAINT interest_rates_pkey PRIMARY KEY (id);


--
-- Name: opcvm_funds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY opcvm_funds
    ADD CONSTRAINT opcvm_funds_pkey PRIMARY KEY (id);


--
-- Name: portfolio_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portfolio_transactions
    ADD CONSTRAINT portfolio_transactions_pkey PRIMARY KEY (id);


--
-- Name: portfolios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portfolios
    ADD CONSTRAINT portfolios_pkey PRIMARY KEY (id);


--
-- Name: scpi_funds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scpi_funds
    ADD CONSTRAINT scpi_funds_pkey PRIMARY KEY (id);


--
-- Name: scpi_quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scpi_quotations
    ADD CONSTRAINT scpi_quotations_pkey PRIMARY KEY (id);


--
-- Name: index_currency_quotations_on_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currency_quotations_on_id_and_date ON currency_quotations USING btree (currency_id, date);


--
-- Name: index_interest_rates_on_object_type_and_object_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_interest_rates_on_object_type_and_object_id ON interest_rates USING btree (object_type, object_id);


--
-- Name: index_matview_opcvm_quotations_eur_on_opcvm_fund_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_matview_opcvm_quotations_eur_on_opcvm_fund_id_and_date ON matview_opcvm_quotations_eur USING btree (opcvm_fund_id, date);


--
-- Name: index_matview_opcvm_quotations_filled_eur_on_opcvm_fund_id_and_; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_matview_opcvm_quotations_filled_eur_on_opcvm_fund_id_and_ ON matview_opcvm_quotations_filled_eur USING btree (opcvm_fund_id, date);


--
-- Name: index_matview_scpi_quotations_eur_on_scpi_fund_id_and_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_matview_scpi_quotations_eur_on_scpi_fund_id_and_date ON matview_scpi_quotations_eur USING btree (scpi_fund_id, date);


--
-- Name: index_matview_scpi_quotations_filled_eur_on_scpi_fund_id_and_da; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_matview_scpi_quotations_filled_eur_on_scpi_fund_id_and_da ON matview_scpi_quotations_filled_eur USING btree (scpi_fund_id, date);


--
-- Name: index_opcvm_quotations_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opcvm_quotations_on_date ON opcvm_quotations USING btree (date);


--
-- Name: index_opcvm_quotations_on_date_and_fund; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_opcvm_quotations_on_date_and_fund ON opcvm_quotations USING btree (opcvm_fund_id, date);


--
-- Name: index_portfolio_transactions_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_portfolio_transactions_on_date ON portfolio_transactions USING btree (done_at);


--
-- Name: index_portfolio_transactions_on_date_and_fund; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_portfolio_transactions_on_date_and_fund ON portfolio_transactions USING btree (fund_id, fund_type, done_at);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: fk_rails_304e76d585; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scpi_quotations
    ADD CONSTRAINT fk_rails_304e76d585 FOREIGN KEY (scpi_fund_id) REFERENCES scpi_funds(id);


--
-- Name: fk_rails_6aaddc1d5a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY portfolio_transactions
    ADD CONSTRAINT fk_rails_6aaddc1d5a FOREIGN KEY (portfolio_id) REFERENCES portfolios(id);


--
-- Name: fk_rails_9223c12f29; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY currency_quotations
    ADD CONSTRAINT fk_rails_9223c12f29 FOREIGN KEY (currency_id) REFERENCES currencies(id);


--
-- Name: fk_rails_b6a68318ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY opcvm_quotations
    ADD CONSTRAINT fk_rails_b6a68318ce FOREIGN KEY (opcvm_fund_id) REFERENCES opcvm_funds(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20150207160717');

INSERT INTO schema_migrations (version) VALUES ('20150207165602');

INSERT INTO schema_migrations (version) VALUES ('20150207173634');

INSERT INTO schema_migrations (version) VALUES ('20150207183353');

INSERT INTO schema_migrations (version) VALUES ('20150207183439');

INSERT INTO schema_migrations (version) VALUES ('20150207190237');

INSERT INTO schema_migrations (version) VALUES ('20150207192444');

INSERT INTO schema_migrations (version) VALUES ('20150207192516');

INSERT INTO schema_migrations (version) VALUES ('20150207203536');

INSERT INTO schema_migrations (version) VALUES ('20150207204046');

INSERT INTO schema_migrations (version) VALUES ('20150207232435');

INSERT INTO schema_migrations (version) VALUES ('20150222170611');

INSERT INTO schema_migrations (version) VALUES ('20150222170901');

INSERT INTO schema_migrations (version) VALUES ('20150222171347');

INSERT INTO schema_migrations (version) VALUES ('20150222175449');

INSERT INTO schema_migrations (version) VALUES ('20150222194703');

INSERT INTO schema_migrations (version) VALUES ('20150222200034');

INSERT INTO schema_migrations (version) VALUES ('20150222210141');

INSERT INTO schema_migrations (version) VALUES ('20150319225928');

INSERT INTO schema_migrations (version) VALUES ('20150319231431');

INSERT INTO schema_migrations (version) VALUES ('20150320010344');

INSERT INTO schema_migrations (version) VALUES ('20150320010832');

INSERT INTO schema_migrations (version) VALUES ('20150516124653');

INSERT INTO schema_migrations (version) VALUES ('20160313201117');

INSERT INTO schema_migrations (version) VALUES ('20160313223232');

INSERT INTO schema_migrations (version) VALUES ('20160313224012');

INSERT INTO schema_migrations (version) VALUES ('20160411135657');

INSERT INTO schema_migrations (version) VALUES ('20160504115339');

INSERT INTO schema_migrations (version) VALUES ('20160504115439');

INSERT INTO schema_migrations (version) VALUES ('20160504115444');

INSERT INTO schema_migrations (version) VALUES ('20160504115456');

INSERT INTO schema_migrations (version) VALUES ('20160504115505');

INSERT INTO schema_migrations (version) VALUES ('20160504115515');

INSERT INTO schema_migrations (version) VALUES ('20160504115527');

INSERT INTO schema_migrations (version) VALUES ('20160504115535');

INSERT INTO schema_migrations (version) VALUES ('20160504115541');

INSERT INTO schema_migrations (version) VALUES ('20160504131146');

INSERT INTO schema_migrations (version) VALUES ('20160622234329');

INSERT INTO schema_migrations (version) VALUES ('20160622234934');

INSERT INTO schema_migrations (version) VALUES ('20160622235000');

INSERT INTO schema_migrations (version) VALUES ('20160622235100');

INSERT INTO schema_migrations (version) VALUES ('20160622235200');

INSERT INTO schema_migrations (version) VALUES ('20160622235300');

INSERT INTO schema_migrations (version) VALUES ('20160629050856');

INSERT INTO schema_migrations (version) VALUES ('20160713004331');

INSERT INTO schema_migrations (version) VALUES ('20160713011027');

INSERT INTO schema_migrations (version) VALUES ('20160713043900');

INSERT INTO schema_migrations (version) VALUES ('20160713043901');

INSERT INTO schema_migrations (version) VALUES ('20160713043902');

INSERT INTO schema_migrations (version) VALUES ('20160713043903');

INSERT INTO schema_migrations (version) VALUES ('20160713044223');

INSERT INTO schema_migrations (version) VALUES ('20160713050658');

INSERT INTO schema_migrations (version) VALUES ('20160713210038');

INSERT INTO schema_migrations (version) VALUES ('20160713211002');

INSERT INTO schema_migrations (version) VALUES ('20160713213012');

INSERT INTO schema_migrations (version) VALUES ('20160713214655');

INSERT INTO schema_migrations (version) VALUES ('20160713220131');

INSERT INTO schema_migrations (version) VALUES ('20160713221510');

INSERT INTO schema_migrations (version) VALUES ('20160713222331');

