# frozen_string_literal: true

require 'test_helper'

class NewOhlcForTimeframeJobTest < ActiveJob::TestCase
  test 'creates the inital OHLC' do
    Trade.create_partition_for_asset(asset_pairs(:atomusd).id, asset_pairs(:atomusd).name)

    asset_pair = asset_pairs(:atomusd)

    Trade.create!(id: [asset_pair.id, 1], price: 1, volume: 1, action: 'buy',
                  order_type: 'market', misc: '')

    range = Ohlc::Range.new('PT1H', Time.current)

    travel 1.hour

    Ohlc.expects(:create_from_trades).with(asset_pair, 'PT1H', range)

    NewOhlcForTimeframeJob.perform_now(asset_pair, 'PT1H', Time.current)
  end

  test 'creates new OHLC' do
    asset_pair = asset_pairs(:atomusd)
    range = Ohlc::Range.new('PT1H', Time.current)
    Ohlc.create!(asset_pair:, high: 1, low: 1, open: 1, close: 1, volume: 1, timeframe: 'PT1H', start_at: range.begin)

    travel 2.hours

    Ohlc.expects(:create_from_trades).with(asset_pair, 'PT1H', range.next)

    NewOhlcForTimeframeJob.perform_now(asset_pair, 'PT1H', Time.current)
  end

  test 'does not create new OHLC for a timeframe that is not finished' do
    asset_pair = asset_pairs(:atomusd)
    range = Ohlc::Range.new('PT1H', Time.current)
    Ohlc.create!(asset_pair:, high: 1, low: 1, open: 1, close: 1, volume: 1, timeframe: 'PT1H', start_at: range.begin)

    travel 1.hour

    Ohlc.expects(:create_from_trades).never

    NewOhlcForTimeframeJob.perform_now(asset_pair, 'PT1H', Time.current)
  end
end
