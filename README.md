# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# TODO:

Calculate OHLC with materialized views

```
SELECT
  DISTINCT ON (date_trunc('hour', created_at))
  date_trunc('hour', created_at) AS timestamp,
  FIRST_VALUE(price) OVER w AS open,
  MAX(price) OVER w AS high,
  MIN(price) OVER w AS low,
  LAST_VALUE(price) OVER w AS close,
  SUM(volume) OVER W AS volume
FROM asset_1inch_trades
WINDOW w AS (
  PARTITION BY date_trunc('hour', created_at)
  ORDER BY created_at
  RANGE BETWEEN 
    UNBOUNDED PRECEDING AND 
    UNBOUNDED FOLLOWING
)
```
