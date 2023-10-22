SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: order_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.order_type AS ENUM (
    'market',
    'limit'
);


--
-- Name: trade_action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.trade_action AS ENUM (
    'buy',
    'sell'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: asset_pairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pairs (
    id bigint NOT NULL,
    name character varying NOT NULL,
    sync boolean DEFAULT false NOT NULL,
    kraken_cursor_position bigint DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: asset_pairs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_pairs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_pairs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_pairs_id_seq OWNED BY public.asset_pairs.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: trades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trades (
    id bigint NOT NULL,
    asset_pair_id bigint NOT NULL,
    price double precision NOT NULL,
    volume double precision NOT NULL,
    created_at timestamp without time zone NOT NULL,
    action public.trade_action NOT NULL,
    order_type public.order_type NOT NULL,
    misc character varying NOT NULL
)
PARTITION BY LIST (asset_pair_id);


--
-- Name: asset_pairs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pairs ALTER COLUMN id SET DEFAULT nextval('public.asset_pairs_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: asset_pairs asset_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pairs
    ADD CONSTRAINT asset_pairs_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: trades trades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_pkey PRIMARY KEY (asset_pair_id, id);


--
-- Name: index_asset_pairs_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_asset_pairs_on_name ON public.asset_pairs USING btree (name);


--
-- Name: trades fk_rails_2ef4d7a130; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trades
    ADD CONSTRAINT fk_rails_2ef4d7a130 FOREIGN KEY (asset_pair_id) REFERENCES public.asset_pairs(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20231022155204'),
('20231022151405'),
('20231022150331'),
('20231022144646'),
('20231021145729'),
('20231018170228'),
('20231018161855'),
('20231015063555'),
('20231014070704'),
('20231014055916'),
('20231011165601');

