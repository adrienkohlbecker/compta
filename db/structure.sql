--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

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
-- Name: currencies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE currencies (
    id integer NOT NULL,
    name character varying,
    boursorama_id character varying,
    url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: currency_quotations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
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
-- Name: euro_funds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
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
-- Name: opcvm_quotations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
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
-- Name: interest_rates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
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
-- Name: matview_eur_to_currency; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_eur_to_currency AS
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
  WITH NO DATA;


--
-- Name: matview_euro_fund_interest_filled; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_euro_fund_interest_filled AS
 SELECT euro_funds.id AS euro_fund_id,
    date(date_series.date_series) AS date,
    t.minimal_rate,
    t.served_rate,
    t.year_length,
    (COALESCE(t.served_rate, t.minimal_rate) * ((1)::numeric - t.social_tax_rate)) AS rate_for_computation
   FROM ((generate_series((( SELECT min(interest_rates."from") AS min
           FROM interest_rates))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
     CROSS JOIN euro_funds)
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
          WHERE (((interest_rates."from" <= date_series.date_series) AND (interest_rates.object_id = euro_funds.id)) AND ((interest_rates.object_type)::text = 'EuroFund'::text))
          ORDER BY interest_rates."to" DESC
         LIMIT 1) t ON (true))
  WITH NO DATA;


--
-- Name: opcvm_funds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
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
-- Name: matview_opcvm_quotations_filled; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled AS
 SELECT opcvm_funds.id AS opcvm_fund_id,
    date(date_series.date_series) AS date,
    t.value_original,
    t.value_currency,
    t.value_date
   FROM ((generate_series((( SELECT min(opcvm_quotations.date) AS min
           FROM opcvm_quotations))::timestamp without time zone, ((transaction_timestamp())::date + '30 days'::interval), '1 day'::interval) date_series(date_series)
     CROSS JOIN opcvm_funds)
     JOIN LATERAL ( SELECT opcvm_quotations.id,
            opcvm_quotations.opcvm_fund_id,
            opcvm_quotations.value_original,
            opcvm_quotations.date,
            opcvm_quotations.created_at,
            opcvm_quotations.updated_at,
            opcvm_quotations.value_currency,
            opcvm_quotations.value_date
           FROM opcvm_quotations
          WHERE ((opcvm_quotations.date <= date_series.date_series) AND (opcvm_quotations.opcvm_fund_id = opcvm_funds.id))
          ORDER BY opcvm_quotations.date DESC
         LIMIT 1) t ON (true))
  WITH NO DATA;


--
-- Name: matview_opcvm_quotations_filled_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_opcvm_quotations_filled_eur AS
 SELECT matview_opcvm_quotations_filled.opcvm_fund_id,
    matview_opcvm_quotations_filled.date,
        CASE
            WHEN ((matview_opcvm_quotations_filled.value_currency)::text = 'EUR'::text) THEN matview_opcvm_quotations_filled.value_original
            ELSE (matview_opcvm_quotations_filled.value_original / matview_eur_to_currency.value)
        END AS value_original,
    'EUR'::character varying AS value_currency,
    matview_opcvm_quotations_filled.value_date
   FROM (matview_opcvm_quotations_filled
     LEFT JOIN matview_eur_to_currency ON (((matview_opcvm_quotations_filled.value_date = matview_eur_to_currency.date) AND ((matview_opcvm_quotations_filled.value_currency)::text = (matview_eur_to_currency.currency_name)::text))))
  WITH NO DATA;


--
-- Name: portfolio_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
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
-- Name: matview_portfolio_transactions_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_portfolio_transactions_eur AS
 SELECT portfolio_transactions.id,
    portfolio_transactions.fund_id,
    portfolio_transactions.shares,
    portfolio_transactions.portfolio_id,
    portfolio_transactions.done_at,
    portfolio_transactions.fund_type,
    portfolio_transactions.category,
        CASE
            WHEN ((portfolio_transactions.amount_currency)::text = 'EUR'::text) THEN portfolio_transactions.amount_original
            ELSE (portfolio_transactions.amount_original / matview_eur_to_currency_for_amount.value)
        END AS amount_original,
    'EUR'::character varying AS amount_currency,
    portfolio_transactions.amount_date,
        CASE
            WHEN ((portfolio_transactions.shareprice_currency)::text = 'EUR'::text) THEN portfolio_transactions.shareprice_original
            ELSE (portfolio_transactions.shareprice_original / matview_eur_to_currency_for_shareprice.value)
        END AS shareprice_original,
    'EUR'::character varying AS shareprice_currency,
    portfolio_transactions.shareprice_date
   FROM ((portfolio_transactions
     LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_amount ON (((portfolio_transactions.amount_date = matview_eur_to_currency_for_amount.date) AND ((portfolio_transactions.amount_currency)::text = (matview_eur_to_currency_for_amount.currency_name)::text))))
     LEFT JOIN matview_eur_to_currency matview_eur_to_currency_for_shareprice ON (((portfolio_transactions.amount_date = matview_eur_to_currency_for_shareprice.date) AND ((portfolio_transactions.amount_currency)::text = (matview_eur_to_currency_for_shareprice.currency_name)::text))))
  WITH NO DATA;


--
-- Name: matview_portfolio_transactions_with_investment_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_portfolio_transactions_with_investment_eur AS
 SELECT matview_portfolio_transactions_eur.id,
    matview_portfolio_transactions_eur.fund_id,
    matview_portfolio_transactions_eur.shares,
    matview_portfolio_transactions_eur.portfolio_id,
    matview_portfolio_transactions_eur.done_at,
    matview_portfolio_transactions_eur.fund_type,
    matview_portfolio_transactions_eur.category,
    matview_portfolio_transactions_eur.amount_original,
    matview_portfolio_transactions_eur.amount_currency,
    matview_portfolio_transactions_eur.amount_date,
    matview_portfolio_transactions_eur.shareprice_original,
    matview_portfolio_transactions_eur.shareprice_currency,
    matview_portfolio_transactions_eur.shareprice_date,
        CASE
            WHEN (((matview_portfolio_transactions_eur.category)::text = 'Virement'::text) OR ((matview_portfolio_transactions_eur.category)::text = 'Arbitrage'::text)) THEN matview_portfolio_transactions_eur.amount_original
            ELSE (0)::numeric
        END AS invested_original,
    matview_portfolio_transactions_eur.amount_currency AS invested_currency,
    matview_portfolio_transactions_eur.amount_date AS invested_date
   FROM matview_portfolio_transactions_eur
  WITH NO DATA;


--
-- Name: portfolios; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE portfolios (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: matview_portfolio_euro_fund_history_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_portfolio_euro_fund_history_eur AS
 SELECT date(date_series.date_series) AS date,
    euro_funds.id AS fund_id,
    'EuroFund'::character varying AS fund_type,
    portfolios.id AS portfolio_id,
    NULL::numeric(15,5) AS shares,
    invested.invested,
    (((invested.invested + COALESCE(actual_pv.actual_pv, (0)::numeric)) + COALESCE(latent_pv_this_year.latent_pv_this_year, (0)::numeric)) + COALESCE(latent_pv_last_year.latent_pv_last_year, (0)::numeric)) AS current_value
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
          WHERE ((((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text)) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id)) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))) invested ON (true))
     LEFT JOIN LATERAL ( SELECT sum(matview_portfolio_transactions_with_investment_eur.amount_original) AS actual_pv
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE ((((((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text)) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id)) AND (matview_portfolio_transactions_with_investment_eur.done_at < date(date_series.date_series))) AND ((matview_portfolio_transactions_with_investment_eur.category)::text <> 'Virement'::text)) AND ((matview_portfolio_transactions_with_investment_eur.category)::text <> 'Arbitrage'::text))) actual_pv ON (true))
     LEFT JOIN LATERAL ( SELECT sum((matview_portfolio_transactions_with_investment_eur.amount_original * ((((1)::numeric + interest_rate.rate_for_computation) ^ (((date(date_series.date_series) - matview_portfolio_transactions_with_investment_eur.done_at))::numeric / (interest_rate.year_length)::numeric)) - (1)::numeric))) AS latent_pv_this_year
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE (((((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text)) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id)) AND (matview_portfolio_transactions_with_investment_eur.done_at >= (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date)) AND (matview_portfolio_transactions_with_investment_eur.done_at <= date(date_series.date_series)))) latent_pv_this_year ON (true))
     LEFT JOIN LATERAL ( SELECT (sum(matview_portfolio_transactions_with_investment_eur.amount_original) * ((((1)::numeric + interest_rate.rate_for_computation) ^ ((((date(date_series.date_series) - (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date) + 1))::numeric / (interest_rate.year_length)::numeric)) - (1)::numeric)) AS latent_pv_last_year
           FROM matview_portfolio_transactions_with_investment_eur
          WHERE ((((matview_portfolio_transactions_with_investment_eur.fund_id = euro_funds.id) AND ((matview_portfolio_transactions_with_investment_eur.fund_type)::text = 'EuroFund'::text)) AND (matview_portfolio_transactions_with_investment_eur.portfolio_id = portfolios.id)) AND (matview_portfolio_transactions_with_investment_eur.done_at < (date_trunc('year'::text, (date(date_series.date_series))::timestamp with time zone))::date))) latent_pv_last_year ON (true))
  WITH NO DATA;


--
-- Name: matview_portfolio_opcvm_fund_history_eur; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_portfolio_opcvm_fund_history_eur AS
 SELECT date(date_series.date_series) AS date,
    opcvm_funds.id AS fund_id,
    'OpcvmFund'::character varying AS fund_type,
    portfolios.id AS portfolio_id,
    t.shares,
    t.invested,
    (matview_opcvm_quotations_filled_eur.value_original * t.shares) AS current_value
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
     JOIN matview_opcvm_quotations_filled_eur ON (((opcvm_funds.id = matview_opcvm_quotations_filled_eur.opcvm_fund_id) AND (matview_opcvm_quotations_filled_eur.date = date(date_series.date_series)))))
  WITH NO DATA;


--
-- Name: matview_portfolio_history; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_portfolio_history AS
 SELECT history.date,
    history.fund_id,
    history.fund_type,
    history.portfolio_id,
        CASE
            WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
            ELSE history.shares
        END AS shares,
    history.invested,
        CASE
            WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
            ELSE history.current_value
        END AS current_value,
        CASE
            WHEN (abs(history.shares) < 0.001) THEN (- history.invested)
            ELSE (history.current_value - history.invested)
        END AS pv,
        CASE
            WHEN (abs(history.shares) < 0.001) THEN NULL::numeric
            ELSE ((history.current_value / history.invested) - (1)::numeric)
        END AS percent
   FROM ( SELECT matview_portfolio_euro_fund_history_eur.date,
            matview_portfolio_euro_fund_history_eur.fund_id,
            matview_portfolio_euro_fund_history_eur.fund_type,
            matview_portfolio_euro_fund_history_eur.portfolio_id,
            matview_portfolio_euro_fund_history_eur.shares,
            matview_portfolio_euro_fund_history_eur.invested,
            matview_portfolio_euro_fund_history_eur.current_value
           FROM matview_portfolio_euro_fund_history_eur
        UNION
         SELECT matview_portfolio_opcvm_fund_history_eur.date,
            matview_portfolio_opcvm_fund_history_eur.fund_id,
            matview_portfolio_opcvm_fund_history_eur.fund_type,
            matview_portfolio_opcvm_fund_history_eur.portfolio_id,
            matview_portfolio_opcvm_fund_history_eur.shares,
            matview_portfolio_opcvm_fund_history_eur.invested,
            matview_portfolio_opcvm_fund_history_eur.current_value
           FROM matview_portfolio_opcvm_fund_history_eur) history
  ORDER BY history.date, history.portfolio_id, history.fund_type, history.fund_id
  WITH NO DATA;


--
-- Name: matview_portfolio_performance; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW matview_portfolio_performance AS
 SELECT matview_portfolio_history.date,
    matview_portfolio_history.portfolio_id,
    sum(matview_portfolio_history.invested) AS invested,
    sum(matview_portfolio_history.current_value) AS current_value,
    sum(matview_portfolio_history.pv) AS pv
   FROM matview_portfolio_history
  GROUP BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id
  ORDER BY matview_portfolio_history.date, matview_portfolio_history.portfolio_id
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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


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
-- Name: currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (id);


--
-- Name: currency_quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY currency_quotations
    ADD CONSTRAINT currency_quotations_pkey PRIMARY KEY (id);


--
-- Name: euro_funds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY euro_funds
    ADD CONSTRAINT euro_funds_pkey PRIMARY KEY (id);


--
-- Name: fund_quotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY opcvm_quotations
    ADD CONSTRAINT fund_quotations_pkey PRIMARY KEY (id);


--
-- Name: interest_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interest_rates
    ADD CONSTRAINT interest_rates_pkey PRIMARY KEY (id);


--
-- Name: opcvm_funds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY opcvm_funds
    ADD CONSTRAINT opcvm_funds_pkey PRIMARY KEY (id);


--
-- Name: portfolio_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portfolio_transactions
    ADD CONSTRAINT portfolio_transactions_pkey PRIMARY KEY (id);


--
-- Name: portfolios_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY portfolios
    ADD CONSTRAINT portfolios_pkey PRIMARY KEY (id);


--
-- Name: index_currency_quotations_on_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_currency_quotations_on_date ON currency_quotations USING btree (date);


--
-- Name: index_currency_quotations_on_name_and_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_currency_quotations_on_name_and_date ON currency_quotations USING btree (currency_id, date);


--
-- Name: index_opcvm_quotations_on_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_opcvm_quotations_on_date ON opcvm_quotations USING btree (date);


--
-- Name: index_opcvm_quotations_on_date_and_fund; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_opcvm_quotations_on_date_and_fund ON opcvm_quotations USING btree (opcvm_fund_id, date);


--
-- Name: index_portfolio_transactions_on_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_portfolio_transactions_on_date ON portfolio_transactions USING btree (done_at);


--
-- Name: index_portfolio_transactions_on_date_and_fund; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_portfolio_transactions_on_date_and_fund ON portfolio_transactions USING btree (fund_id, fund_type, done_at);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


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

SET search_path TO "$user",public;

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
