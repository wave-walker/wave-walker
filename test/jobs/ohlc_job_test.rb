# frozen_string_literal: true

require 'test_helper'

class OhlcJobTest < ActiveJob::TestCase
  test '.enqueue_for_all_timeframes, enqueues the OHLC for all timeframes' do
    last_imported_at = 1.minute.ago
    asset_pair = asset_pairs(:atomusd)
    timeframes = Ohlc.timeframes.keys

    timeframes.each do |timeframe|
      assert_enqueued_with(job: OhlcJob, args: [asset_pair, timeframe, last_imported_at]) do
        OhlcJob.enqueue_for_all_timeframes(asset_pair, last_imported_at)
      end
    end
  end

  test 'creates the inital OHLC' do
    Trade.create_partition_for_asset(asset_pairs(:atomusd).id, asset_pairs(:atomusd).name)

    asset_pair = asset_pairs(:atomusd)

    Trade.create!(id: [asset_pair.id, 1], price: 1, volume: 1, action: 'buy',
                  order_type: 'market', misc: '')

    range = Ohlc::Range.new('PT1H', Time.current)

    travel 1.hour

    Ohlc.expects(:create_from_trades).with(asset_pair, 'PT1H', range)

    OhlcJob.perform_now(asset_pair, 'PT1H', Time.current)
  end

  test 'creates new OHLC' do
    asset_pair = asset_pairs(:atomusd)
    range = Ohlc::Range.new('PT1H', Time.current)
    Ohlc.create!(asset_pair:, high: 1, low: 1, open: 1, close: 1, volume: 1, timeframe: 'PT1H', start_at: range.begin)

    travel 2.hours

    Ohlc.expects(:create_from_trades).with(asset_pair, 'PT1H', range.next)

    OhlcJob.perform_now(asset_pair, 'PT1H', Time.current)
  end

  test 'does not create new OHLC for a timeframe that is not finished' do
    asset_pair = asset_pairs(:atomusd)
    range = Ohlc::Range.new('PT1H', Time.current)
    Ohlc.create!(asset_pair:, high: 1, low: 1, open: 1, close: 1, volume: 1, timeframe: 'PT1H', start_at: range.begin)

    travel 1.hour

    Ohlc.expects(:create_from_trades).never

    OhlcJob.perform_now(asset_pair, 'PT1H', Time.current)
  end
end
