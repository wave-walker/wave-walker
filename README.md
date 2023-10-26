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

Get trade data with WebSockets

```
require "json"
require 'websocket-eventmachine-client'

# Define the Kraken WebSocket URL
kraken_ws_url = 'wss://ws.kraken.com'

# Define the trading pair for which you want to receive trade data (e.g., BTC/USD)
trading_pair = 'XBT/USD'

# Create a connection to Kraken's WebSocket API
EM.run do
  ws = WebSocket::EventMachine::Client.connect(uri: kraken_ws_url)

  ws.onopen do
    puts "Connected to Kraken WebSocket"

    # Subscribe to trade data for the specified trading pair
    subscription_msg = {
      event: 'subscribe',
      pair: [trading_pair],
      subscription: {
        name: 'trade',
      },
    }

    ws.send(subscription_msg.to_json)
  end

  ws.onmessage do |msg, type|
    data = JSON.parse(msg)
    if data.is_a?(Array)
      p "---> #{data} <---"
    elsif data['event'] == 'subscriptionStatus'
      if data['status'] == 'subscribed'
        puts "Subscribed to #{trading_pair} trade data"
      elsif data['status'] == 'error'
        puts "Subscription error: #{data['errorMessage']}"
      end
    elsif data['event'] == 'trade'
      # Handle trade data here
      puts "Trade Data: #{data}"
    end
  end

  ws.onclose do |code, reason|
    puts "Connection closed with code #{code}, reason: #{reason}"
  end
end
```
