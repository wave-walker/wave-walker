CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "content_type" varchar, "created_at" datetime(6) NOT NULL, "filename" varchar NOT NULL, "key" varchar NOT NULL, "metadata" text, "service_name" varchar NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='WaveWalker'*/;
CREATE TABLE IF NOT EXISTS "asset_pairs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "base" varchar NOT NULL, "cost_decimals" integer NOT NULL, "created_at" datetime(6) NOT NULL, "imported_until" datetime(6), "importing" boolean DEFAULT FALSE NOT NULL, "missing_on_exchange_at" datetime(6), "name" varchar NOT NULL, "name_on_exchange" varchar NOT NULL, "quote" varchar NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_asset_pairs_on_missing_on_exchange_at" ON "asset_pairs" ("missing_on_exchange_at") /*application='WaveWalker'*/;
CREATE UNIQUE INDEX "index_asset_pairs_on_name" ON "asset_pairs" ("name") /*application='WaveWalker'*/;
CREATE UNIQUE INDEX "index_asset_pairs_on_name_on_exchange" ON "asset_pairs" ("name_on_exchange") /*application='WaveWalker'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "name" varchar NOT NULL, "record_id" bigint NOT NULL, "record_type" varchar NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='WaveWalker'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='WaveWalker'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='WaveWalker'*/;
CREATE TABLE IF NOT EXISTS "backtest_trades" ("action" varchar NOT NULL, "asset_pair_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "fee" decimal NOT NULL, "iso8601_duration" varchar NOT NULL, "price" decimal NOT NULL, "range_position" bigint NOT NULL, "updated_at" datetime(6) NOT NULL, "volume" decimal NOT NULL, PRIMARY KEY ("asset_pair_id", "iso8601_duration", "range_position"), CONSTRAINT "fk_rails_9b81f437e7"
FOREIGN KEY ("asset_pair_id")
  REFERENCES "asset_pairs" ("id")
, CONSTRAINT "fk_rails_d36505435c"
FOREIGN KEY ("asset_pair_id", "iso8601_duration", "range_position")
  REFERENCES "ohlcs" ("asset_pair_id", "iso8601_duration", "range_position")
, CONSTRAINT chk_rails_8a5db85d9f CHECK (action IN ('buy', 'sell')), CONSTRAINT chk_rails_f45ff093f8 CHECK (iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')));
CREATE INDEX "index_backtest_trades_on_asset_pair_id" ON "backtest_trades" ("asset_pair_id") /*application='WaveWalker'*/;
CREATE TABLE IF NOT EXISTS "backtests" ("asset_pair_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "current_value" decimal, "iso8601_duration" varchar NOT NULL, "last_range_position" bigint DEFAULT 0 NOT NULL, "token_volume" decimal DEFAULT 0.0 NOT NULL, "updated_at" datetime(6) NOT NULL, "usd_volume" decimal NOT NULL, PRIMARY KEY ("asset_pair_id", "iso8601_duration"), CONSTRAINT "fk_rails_4c83ce810f"
FOREIGN KEY ("asset_pair_id")
  REFERENCES "asset_pairs" ("id")
, CONSTRAINT chk_rails_df09cf9ec9 CHECK (iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')));
CREATE INDEX "index_backtests_on_asset_pair_id" ON "backtests" ("asset_pair_id") /*application='WaveWalker'*/;
CREATE TABLE IF NOT EXISTS "ohlcs" ("asset_pair_id" bigint NOT NULL, "close" decimal NOT NULL, "created_at" datetime(6) NOT NULL, "high" decimal NOT NULL, "iso8601_duration" varchar NOT NULL, "low" decimal NOT NULL, "open" decimal NOT NULL, "range_position" bigint NOT NULL, "updated_at" datetime(6) NOT NULL, "volume" decimal NOT NULL, PRIMARY KEY ("asset_pair_id", "iso8601_duration", "range_position"), CONSTRAINT "fk_rails_053bf281dc"
FOREIGN KEY ("asset_pair_id")
  REFERENCES "asset_pairs" ("id")
, CONSTRAINT chk_rails_59c4f0470a CHECK (iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')));
CREATE TABLE IF NOT EXISTS "smoothed_moving_averages" ("asset_pair_id" bigint NOT NULL, "created_at" datetime NOT NULL, "interval" integer NOT NULL, "iso8601_duration" varchar NOT NULL, "range_position" bigint NOT NULL, "value" decimal NOT NULL, PRIMARY KEY ("asset_pair_id", "iso8601_duration", "range_position", "interval"), CONSTRAINT "fk_rails_a68fdc006c"
FOREIGN KEY ("asset_pair_id")
  REFERENCES "asset_pairs" ("id")
, CONSTRAINT "fk_rails_a00d14048a"
FOREIGN KEY ("asset_pair_id", "iso8601_duration", "range_position")
  REFERENCES "ohlcs" ("asset_pair_id", "iso8601_duration", "range_position")
, CONSTRAINT chk_rails_551824e909 CHECK (iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')));
CREATE TABLE IF NOT EXISTS "smoothed_trends" ("asset_pair_id" bigint NOT NULL, "created_at" datetime NOT NULL, "fast_smma" decimal NOT NULL, "flip" boolean NOT NULL, "iso8601_duration" varchar NOT NULL, "range_position" bigint NOT NULL, "slow_smma" decimal NOT NULL, "trend" varchar NOT NULL, PRIMARY KEY ("asset_pair_id", "iso8601_duration", "range_position"), CONSTRAINT "fk_rails_df50212b75"
FOREIGN KEY ("asset_pair_id")
  REFERENCES "asset_pairs" ("id")
, CONSTRAINT "fk_rails_930a391dec"
FOREIGN KEY ("asset_pair_id", "iso8601_duration", "range_position")
  REFERENCES "ohlcs" ("asset_pair_id", "iso8601_duration", "range_position")
, CONSTRAINT chk_rails_4bd9b66f51 CHECK (iso8601_duration IN ('PT1H', 'PT4H', 'PT8H', 'P1D', 'P2D', 'P1W')), CONSTRAINT chk_rails_6a82c91514 CHECK (trend IN ('bearish', 'neutral', 'bullish')));
CREATE TABLE IF NOT EXISTS "trades" ("action" varchar NOT NULL, "asset_pair_id" bigint NOT NULL, "created_at" datetime NOT NULL, "id" bigint NOT NULL, "misc" varchar NOT NULL, "order_type" varchar NOT NULL, "price" decimal NOT NULL, "volume" decimal NOT NULL, PRIMARY KEY ("asset_pair_id", "id"), CONSTRAINT "fk_rails_2ef4d7a130"
FOREIGN KEY ("asset_pair_id")
  REFERENCES "asset_pairs" ("id")
, CONSTRAINT chk_rails_0b00d22040 CHECK (action IN ('buy', 'sell')), CONSTRAINT chk_rails_fa6fb759b8 CHECK (order_type IN ('market', 'limit')));
CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE VIEW ohlc_statuses AS SELECT asset_pair_id, iso8601_duration, MAX(range_position) AS latest_range_position FROM ohlcs GROUP BY asset_pair_id, iso8601_duration
/* ohlc_statuses(asset_pair_id,iso8601_duration,latest_range_position) */;
INSERT INTO "schema_migrations" (version) VALUES
('20260428204905'),
('20260323222400'),
('20260223174500'),
('20250708230414'),
('20250628060517'),
('20250308161752'),
('20240830150260'),
('20240830150259'),
('20240830150258'),
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

