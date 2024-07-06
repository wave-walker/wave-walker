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
-- Name: iso8601_duration; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.iso8601_duration AS ENUM (
    'PT1H',
    'PT4H',
    'PT8H',
    'P1D',
    'P2D',
    'P1W'
);


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


--
-- Name: trend; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.trend AS ENUM (
    'bearish',
    'neutral',
    'bullish'
);


--
-- Name: create_partition_for_asset_pair(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_partition_for_asset_pair() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ DECLARE asset_pair_id INTEGER; BEGIN asset_pair_id := NEW.id; EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_trades PARTITION OF trades FOR VALUES IN (' || asset_pair_id || ')'; EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_ohlcs PARTITION OF ohlcs FOR VALUES IN (' || asset_pair_id || ')'; EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_smoothed_moving_averages PARTITION OF smoothed_moving_averages FOR VALUES IN (' || asset_pair_id || ')'; EXECUTE 'CREATE TABLE IF NOT EXISTS asset_pair_' || asset_pair_id || '_smoothed_trends PARTITION OF smoothed_trends FOR VALUES IN (' || asset_pair_id || ')'; RETURN NEW; END; $$;


--
-- Name: drop_partition_for_asset_pair(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.drop_partition_for_asset_pair() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ DECLARE asset_pair_id INTEGER; BEGIN asset_pair_id := OLD.id; EXECUTE 'ALTER TABLE smoothed_trends DETACH PARTITION asset_pair_' || asset_pair_id || '_smoothed_trends' CASCADE; EXECUTE 'ALTER TABLE smoothed_moving_averages DETACH PARTITION asset_pair_' || asset_pair_id || '_smoothed_moving_averages' CASCADE; EXECUTE 'ALTER TABLE ohlcs DETACH PARTITION asset_pair_' || asset_pair_id || '_ohlcs' CASCADE; EXECUTE 'ALTER TABLE trades DETACH PARTITION asset_pair_' || asset_pair_id || '_trades' CASCADE; EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_smoothed_trends' CASCADE; EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_smoothed_moving_averages' CASCADE; EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_ohlcs' CASCADE; EXECUTE 'DROP TABLE asset_pair_' || asset_pair_id || '_trades' CASCADE; RETURN NEW; END; $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


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
-- Name: ohlcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ohlcs (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    open numeric NOT NULL,
    high numeric NOT NULL,
    low numeric NOT NULL,
    close numeric NOT NULL,
    volume numeric NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
)
PARTITION BY LIST (asset_pair_id);


--
-- Name: asset_pair_1_ohlcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_1_ohlcs (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    open numeric NOT NULL,
    high numeric NOT NULL,
    low numeric NOT NULL,
    close numeric NOT NULL,
    volume numeric NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: smoothed_moving_averages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.smoothed_moving_averages (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    "interval" integer NOT NULL,
    value numeric NOT NULL,
    created_at timestamp without time zone NOT NULL
)
PARTITION BY LIST (asset_pair_id);


--
-- Name: asset_pair_1_smoothed_moving_averages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_1_smoothed_moving_averages (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    "interval" integer NOT NULL,
    value numeric NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: smoothed_trends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.smoothed_trends (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    fast_smma numeric NOT NULL,
    slow_smma numeric NOT NULL,
    trend public.trend NOT NULL,
    created_at timestamp without time zone NOT NULL,
    flip boolean NOT NULL
)
PARTITION BY LIST (asset_pair_id);


--
-- Name: asset_pair_1_smoothed_trends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_1_smoothed_trends (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    fast_smma numeric NOT NULL,
    slow_smma numeric NOT NULL,
    trend public.trend NOT NULL,
    created_at timestamp without time zone NOT NULL,
    flip boolean NOT NULL
);


--
-- Name: trades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trades (
    id bigint NOT NULL,
    asset_pair_id bigint NOT NULL,
    price numeric NOT NULL,
    volume numeric NOT NULL,
    created_at timestamp without time zone NOT NULL,
    action public.trade_action NOT NULL,
    order_type public.order_type NOT NULL,
    misc character varying NOT NULL
)
PARTITION BY LIST (asset_pair_id);


--
-- Name: asset_pair_1_trades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_1_trades (
    id bigint NOT NULL,
    asset_pair_id bigint NOT NULL,
    price numeric NOT NULL,
    volume numeric NOT NULL,
    created_at timestamp without time zone NOT NULL,
    action public.trade_action NOT NULL,
    order_type public.order_type NOT NULL,
    misc character varying NOT NULL
);


--
-- Name: asset_pair_2_ohlcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_2_ohlcs (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    open numeric NOT NULL,
    high numeric NOT NULL,
    low numeric NOT NULL,
    close numeric NOT NULL,
    volume numeric NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: asset_pair_2_smoothed_moving_averages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_2_smoothed_moving_averages (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    "interval" integer NOT NULL,
    value numeric NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: asset_pair_2_smoothed_trends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_2_smoothed_trends (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    fast_smma numeric NOT NULL,
    slow_smma numeric NOT NULL,
    trend public.trend NOT NULL,
    created_at timestamp without time zone NOT NULL,
    flip boolean NOT NULL
);


--
-- Name: asset_pair_2_trades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pair_2_trades (
    id bigint NOT NULL,
    asset_pair_id bigint NOT NULL,
    price numeric NOT NULL,
    volume numeric NOT NULL,
    created_at timestamp without time zone NOT NULL,
    action public.trade_action NOT NULL,
    order_type public.order_type NOT NULL,
    misc character varying NOT NULL
);


--
-- Name: asset_pairs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_pairs (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    importing boolean DEFAULT false NOT NULL,
    name_on_exchange character varying NOT NULL,
    imported_until timestamp(6) without time zone,
    quote character varying NOT NULL,
    base character varying NOT NULL,
    cost_decimals integer NOT NULL
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
-- Name: backtest_trades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.backtest_trades (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    range_position bigint NOT NULL,
    action public.trade_action NOT NULL,
    volume numeric NOT NULL,
    fee numeric NOT NULL,
    price numeric NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: backtests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.backtests (
    asset_pair_id bigint NOT NULL,
    iso8601_duration public.iso8601_duration NOT NULL,
    last_range_position bigint DEFAULT 0 NOT NULL,
    token_volume numeric DEFAULT 0.0 NOT NULL,
    usd_volume numeric NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    current_value numeric
);


--
-- Name: good_job_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_batches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    description text,
    serialized_properties jsonb,
    on_finish text,
    on_success text,
    on_discard text,
    callback_queue_name text,
    callback_priority integer,
    enqueued_at timestamp(6) without time zone,
    discarded_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone
);


--
-- Name: good_job_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_executions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    active_job_id uuid NOT NULL,
    job_class text,
    queue_name text,
    serialized_params jsonb,
    scheduled_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    error text,
    error_event smallint,
    error_backtrace text[],
    process_id uuid,
    duration interval
);


--
-- Name: good_job_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_processes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    state jsonb,
    lock_type smallint
);


--
-- Name: good_job_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_job_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    key text,
    value jsonb
);


--
-- Name: good_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.good_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    queue_name text,
    priority integer,
    serialized_params jsonb,
    scheduled_at timestamp(6) without time zone,
    performed_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    error text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    active_job_id uuid,
    concurrency_key text,
    cron_key text,
    retried_good_job_id uuid,
    cron_at timestamp(6) without time zone,
    batch_id uuid,
    batch_callback_id uuid,
    is_discrete boolean,
    executions_count integer,
    job_class text,
    error_event smallint,
    labels text[],
    locked_by_id uuid,
    locked_at timestamp(6) without time zone
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: asset_pair_1_ohlcs; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ohlcs ATTACH PARTITION public.asset_pair_1_ohlcs FOR VALUES IN ('1');


--
-- Name: asset_pair_1_smoothed_moving_averages; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smoothed_moving_averages ATTACH PARTITION public.asset_pair_1_smoothed_moving_averages FOR VALUES IN ('1');


--
-- Name: asset_pair_1_smoothed_trends; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smoothed_trends ATTACH PARTITION public.asset_pair_1_smoothed_trends FOR VALUES IN ('1');


--
-- Name: asset_pair_1_trades; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades ATTACH PARTITION public.asset_pair_1_trades FOR VALUES IN ('1');


--
-- Name: asset_pair_2_ohlcs; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ohlcs ATTACH PARTITION public.asset_pair_2_ohlcs FOR VALUES IN ('2');


--
-- Name: asset_pair_2_smoothed_moving_averages; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smoothed_moving_averages ATTACH PARTITION public.asset_pair_2_smoothed_moving_averages FOR VALUES IN ('2');


--
-- Name: asset_pair_2_smoothed_trends; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smoothed_trends ATTACH PARTITION public.asset_pair_2_smoothed_trends FOR VALUES IN ('2');


--
-- Name: asset_pair_2_trades; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades ATTACH PARTITION public.asset_pair_2_trades FOR VALUES IN ('2');


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: asset_pairs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pairs ALTER COLUMN id SET DEFAULT nextval('public.asset_pairs_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: ohlcs ohlcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ohlcs
    ADD CONSTRAINT ohlcs_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position);


--
-- Name: asset_pair_1_ohlcs asset_pair_1_ohlcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_1_ohlcs
    ADD CONSTRAINT asset_pair_1_ohlcs_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position);


--
-- Name: smoothed_moving_averages smoothed_moving_averages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smoothed_moving_averages
    ADD CONSTRAINT smoothed_moving_averages_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position, "interval");


--
-- Name: asset_pair_1_smoothed_moving_averages asset_pair_1_smoothed_moving_averages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_1_smoothed_moving_averages
    ADD CONSTRAINT asset_pair_1_smoothed_moving_averages_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position, "interval");


--
-- Name: smoothed_trends smoothed_trends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.smoothed_trends
    ADD CONSTRAINT smoothed_trends_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position);


--
-- Name: asset_pair_1_smoothed_trends asset_pair_1_smoothed_trends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_1_smoothed_trends
    ADD CONSTRAINT asset_pair_1_smoothed_trends_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position);


--
-- Name: trades trades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_pkey PRIMARY KEY (asset_pair_id, id);


--
-- Name: asset_pair_1_trades asset_pair_1_trades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_1_trades
    ADD CONSTRAINT asset_pair_1_trades_pkey PRIMARY KEY (asset_pair_id, id);


--
-- Name: asset_pair_2_ohlcs asset_pair_2_ohlcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_2_ohlcs
    ADD CONSTRAINT asset_pair_2_ohlcs_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position);


--
-- Name: asset_pair_2_smoothed_moving_averages asset_pair_2_smoothed_moving_averages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_2_smoothed_moving_averages
    ADD CONSTRAINT asset_pair_2_smoothed_moving_averages_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position, "interval");


--
-- Name: asset_pair_2_smoothed_trends asset_pair_2_smoothed_trends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_2_smoothed_trends
    ADD CONSTRAINT asset_pair_2_smoothed_trends_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position);


--
-- Name: asset_pair_2_trades asset_pair_2_trades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pair_2_trades
    ADD CONSTRAINT asset_pair_2_trades_pkey PRIMARY KEY (asset_pair_id, id);


--
-- Name: asset_pairs asset_pairs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_pairs
    ADD CONSTRAINT asset_pairs_pkey PRIMARY KEY (id);


--
-- Name: backtest_trades backtest_trades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backtest_trades
    ADD CONSTRAINT backtest_trades_pkey PRIMARY KEY (asset_pair_id, iso8601_duration, range_position);


--
-- Name: backtests backtests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backtests
    ADD CONSTRAINT backtests_pkey PRIMARY KEY (asset_pair_id, iso8601_duration);


--
-- Name: good_job_batches good_job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_batches
    ADD CONSTRAINT good_job_batches_pkey PRIMARY KEY (id);


--
-- Name: good_job_executions good_job_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_executions
    ADD CONSTRAINT good_job_executions_pkey PRIMARY KEY (id);


--
-- Name: good_job_processes good_job_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_processes
    ADD CONSTRAINT good_job_processes_pkey PRIMARY KEY (id);


--
-- Name: good_job_settings good_job_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_job_settings
    ADD CONSTRAINT good_job_settings_pkey PRIMARY KEY (id);


--
-- Name: good_jobs good_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.good_jobs
    ADD CONSTRAINT good_jobs_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_asset_pairs_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_asset_pairs_on_name ON public.asset_pairs USING btree (name);


--
-- Name: index_asset_pairs_on_name_on_exchange; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_asset_pairs_on_name_on_exchange ON public.asset_pairs USING btree (name_on_exchange);


--
-- Name: index_backtest_trades_on_asset_pair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_backtest_trades_on_asset_pair_id ON public.backtest_trades USING btree (asset_pair_id);


--
-- Name: index_backtests_on_asset_pair_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_backtests_on_asset_pair_id ON public.backtests USING btree (asset_pair_id);


--
-- Name: index_good_job_executions_on_active_job_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_job_executions_on_active_job_id_and_created_at ON public.good_job_executions USING btree (active_job_id, created_at);


--
-- Name: index_good_job_executions_on_process_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_job_executions_on_process_id_and_created_at ON public.good_job_executions USING btree (process_id, created_at);


--
-- Name: index_good_job_jobs_for_candidate_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_job_jobs_for_candidate_lookup ON public.good_jobs USING btree (priority, created_at) WHERE (finished_at IS NULL);


--
-- Name: index_good_job_settings_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_good_job_settings_on_key ON public.good_job_settings USING btree (key);


--
-- Name: index_good_jobs_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_jobs_on_finished_at ON public.good_jobs USING btree (finished_at) WHERE ((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL));


--
-- Name: index_good_jobs_jobs_on_priority_created_at_when_unfinished; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_jobs_on_priority_created_at_when_unfinished ON public.good_jobs USING btree (priority DESC NULLS LAST, created_at) WHERE (finished_at IS NULL);


--
-- Name: index_good_jobs_on_active_job_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_active_job_id_and_created_at ON public.good_jobs USING btree (active_job_id, created_at);


--
-- Name: index_good_jobs_on_batch_callback_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_batch_callback_id ON public.good_jobs USING btree (batch_callback_id) WHERE (batch_callback_id IS NOT NULL);


--
-- Name: index_good_jobs_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_batch_id ON public.good_jobs USING btree (batch_id) WHERE (batch_id IS NOT NULL);


--
-- Name: index_good_jobs_on_concurrency_key_when_unfinished; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_concurrency_key_when_unfinished ON public.good_jobs USING btree (concurrency_key) WHERE (finished_at IS NULL);


--
-- Name: index_good_jobs_on_cron_key_and_created_at_cond; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_cron_key_and_created_at_cond ON public.good_jobs USING btree (cron_key, created_at) WHERE (cron_key IS NOT NULL);


--
-- Name: index_good_jobs_on_cron_key_and_cron_at_cond; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_good_jobs_on_cron_key_and_cron_at_cond ON public.good_jobs USING btree (cron_key, cron_at) WHERE (cron_key IS NOT NULL);


--
-- Name: index_good_jobs_on_labels; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_labels ON public.good_jobs USING gin (labels) WHERE (labels IS NOT NULL);


--
-- Name: index_good_jobs_on_locked_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_locked_by_id ON public.good_jobs USING btree (locked_by_id) WHERE (locked_by_id IS NOT NULL);


--
-- Name: index_good_jobs_on_priority_scheduled_at_unfinished_unlocked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_priority_scheduled_at_unfinished_unlocked ON public.good_jobs USING btree (priority, scheduled_at) WHERE ((finished_at IS NULL) AND (locked_by_id IS NULL));


--
-- Name: index_good_jobs_on_queue_name_and_scheduled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_queue_name_and_scheduled_at ON public.good_jobs USING btree (queue_name, scheduled_at) WHERE (finished_at IS NULL);


--
-- Name: index_good_jobs_on_scheduled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_good_jobs_on_scheduled_at ON public.good_jobs USING btree (scheduled_at) WHERE (finished_at IS NULL);


--
-- Name: asset_pair_1_ohlcs_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ohlcs_pkey ATTACH PARTITION public.asset_pair_1_ohlcs_pkey;


--
-- Name: asset_pair_1_smoothed_moving_averages_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.smoothed_moving_averages_pkey ATTACH PARTITION public.asset_pair_1_smoothed_moving_averages_pkey;


--
-- Name: asset_pair_1_smoothed_trends_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.smoothed_trends_pkey ATTACH PARTITION public.asset_pair_1_smoothed_trends_pkey;


--
-- Name: asset_pair_1_trades_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trades_pkey ATTACH PARTITION public.asset_pair_1_trades_pkey;


--
-- Name: asset_pair_2_ohlcs_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.ohlcs_pkey ATTACH PARTITION public.asset_pair_2_ohlcs_pkey;


--
-- Name: asset_pair_2_smoothed_moving_averages_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.smoothed_moving_averages_pkey ATTACH PARTITION public.asset_pair_2_smoothed_moving_averages_pkey;


--
-- Name: asset_pair_2_smoothed_trends_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.smoothed_trends_pkey ATTACH PARTITION public.asset_pair_2_smoothed_trends_pkey;


--
-- Name: asset_pair_2_trades_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.trades_pkey ATTACH PARTITION public.asset_pair_2_trades_pkey;


--
-- Name: asset_pairs create_partition_for_asset_pair; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_partition_for_asset_pair AFTER INSERT ON public.asset_pairs FOR EACH ROW EXECUTE FUNCTION public.create_partition_for_asset_pair();


--
-- Name: asset_pairs drop_partition_for_asset_pair; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER drop_partition_for_asset_pair AFTER DELETE ON public.asset_pairs FOR EACH ROW EXECUTE FUNCTION public.drop_partition_for_asset_pair();


--
-- Name: ohlcs fk_rails_053bf281dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.ohlcs
    ADD CONSTRAINT fk_rails_053bf281dc FOREIGN KEY (asset_pair_id) REFERENCES public.asset_pairs(id);


--
-- Name: smoothed_trends fk_rails_2379cb27be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.smoothed_trends
    ADD CONSTRAINT fk_rails_2379cb27be FOREIGN KEY (asset_pair_id, iso8601_duration, range_position) REFERENCES public.ohlcs(asset_pair_id, iso8601_duration, range_position);


--
-- Name: trades fk_rails_2ef4d7a130; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.trades
    ADD CONSTRAINT fk_rails_2ef4d7a130 FOREIGN KEY (asset_pair_id) REFERENCES public.asset_pairs(id);


--
-- Name: backtests fk_rails_4c83ce810f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backtests
    ADD CONSTRAINT fk_rails_4c83ce810f FOREIGN KEY (asset_pair_id) REFERENCES public.asset_pairs(id);


--
-- Name: smoothed_moving_averages fk_rails_8983b830fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.smoothed_moving_averages
    ADD CONSTRAINT fk_rails_8983b830fb FOREIGN KEY (asset_pair_id, iso8601_duration, range_position) REFERENCES public.ohlcs(asset_pair_id, iso8601_duration, range_position);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: backtest_trades fk_rails_9b81f437e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backtest_trades
    ADD CONSTRAINT fk_rails_9b81f437e7 FOREIGN KEY (asset_pair_id) REFERENCES public.asset_pairs(id);


--
-- Name: smoothed_moving_averages fk_rails_a68fdc006c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.smoothed_moving_averages
    ADD CONSTRAINT fk_rails_a68fdc006c FOREIGN KEY (asset_pair_id) REFERENCES public.asset_pairs(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: backtest_trades fk_rails_d36505435c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backtest_trades
    ADD CONSTRAINT fk_rails_d36505435c FOREIGN KEY (asset_pair_id, iso8601_duration, range_position) REFERENCES public.ohlcs(asset_pair_id, iso8601_duration, range_position);


--
-- Name: smoothed_trends fk_rails_df50212b75; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.smoothed_trends
    ADD CONSTRAINT fk_rails_df50212b75 FOREIGN KEY (asset_pair_id) REFERENCES public.asset_pairs(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240706065400'),
('20240623115062'),
('20240623115061'),
('20240623115060'),
('20240623115059'),
('20240623115058'),
('20240623115057'),
('20240623115056'),
('20240623115055'),
('20240623115054'),
('20240623115053'),
('20240623115052'),
('20240623115051'),
('20240623115050'),
('20240623022510'),
('20240521160715'),
('20240521150441'),
('20240508150348'),
('20240508150235'),
('20240505080719'),
('20240504162349'),
('20240504083915'),
('20240426161436'),
('20240425145649'),
('20240417144243'),
('20240414121401'),
('20240406151935'),
('20240406140027'),
('20240329105130'),
('20240328144026'),
('20240326132858'),
('20240324052444'),
('20240323123105'),
('20240323010629'),
('20240217155603'),
('20231125151612'),
('20231122153847'),
('20231119163918'),
('20231119143912'),
('20231028141732'),
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

