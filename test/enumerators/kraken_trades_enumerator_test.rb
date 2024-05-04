# frozen_string_literal: true

require 'test_helper'

class KrakenTradesEnumeratorTest < ActiveSupport::TestCase
  setup do
    KrakenTradesEnumerator.reset_load_trades_limit!
  end

  test 'request the first trades if latest trade is not present' do
    asset_pair = AssetPair.new(name_on_exchange: 'ATOMUSD')
    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 0)
          .returns({ trades: [], last: 1 })

    KrakenTradesEnumerator.call(asset_pair, cursor: nil).first
  end

  test 'continues import after the latest trade' do
    asset_pair = asset_pairs(:atomusd)

    Trade.create!(
      id: [asset_pair.id, 1],
      price: 1, volume: 1, action: 'buy',
      order_type: 'market', misc: '',
      created_at: Time.zone.at(1234)
    )

    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 1234)
          .returns({ trades: [], last: 1 })

    KrakenTradesEnumerator.call(asset_pair, cursor: nil).first
  end

  test 'load next trades with the cursor position and ends with no trades' do
    Limiter::Clock.stubs(:sleep)

    asset_pair = AssetPair.new(name_on_exchange: 'ATOMUSD')
    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 0)
          .returns({ trades: %i[trade_a trade_b], last: 3 })

    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 3)
          .returns({ trades: [], last: 4 })

    KrakenTradesEnumerator.call(asset_pair, cursor: nil).to_a
  end

  test 'yields the trades and cursor' do
    asset_pair = AssetPair.new(name_on_exchange: 'ATOMUSD')

    trades = %i[trade_a trade_b]
    cursor = 2

    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 0)
          .returns({ trades:, last: cursor })

    trades_yield = KrakenTradesEnumerator.call(asset_pair, cursor: nil).first
    assert_equal trades_yield[0], { asset_pair:, trades: }
    assert_equal trades_yield[1], cursor
  end

  test 'rate limites the API requests to 1 per second' do
    Limiter::Clock.expects(:sleep).with do |sleep_time|
      assert_in_delta sleep_time, 1, 0.2
    end

    asset_pair = AssetPair.new(name_on_exchange: 'ATOMUSD')
    Kraken.stubs(:trades).with(pair: 'ATOMUSD', since: 0)
          .returns({ trades: %i[trade_a trade_b], last: 3 })

    Kraken.stubs(:trades).with(pair: 'ATOMUSD', since: 3)
          .returns({ trades: [], last: 4 })

    KrakenTradesEnumerator.call(asset_pair, cursor: nil).to_a
  end
end
