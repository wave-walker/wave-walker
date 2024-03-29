# frozen_string_literal: true

require 'test_helper'

class OhlcJobTest < ActiveJob::TestCase
  test '.enqueue_for_all_timeframes, enqueues the OHLC for all timeframes' do
    last_imported_at = 1.minute.ago
    asset_pair = asset_pairs(:atomusd)
    timeframes = Ohlc.timeframes.keys

    OhlcJob.enqueue_for_all_timeframes(asset_pair, last_imported_at)

    timeframes.each do |timeframe|
      assert_enqueued_with(job: OhlcJob, args: [{asset_pair:, timeframe:, last_imported_at:}])
    end
  end

  test '#perform, creates the inital OHLC' do
    asset_pair = asset_pairs(:atomusd)

    PartitionService.call(asset_pair)

    Trade.create!(
      id: [asset_pair.id, 1],
      price: 1, volume: 1, action: 'buy',
      order_type: 'market', misc: '',
      created_at: 2.hours.ago
    )

    Trade.create!(
      id: [asset_pair.id, 2],
      price: 1, volume: 1, action: 'buy',
      order_type: 'market', misc: '',
      created_at: 1.hour.ago
    )

    assert_difference 'Ohlc.count', 2 do
      OhlcJob.perform_now(asset_pair:, timeframe: 'PT1H', last_imported_at: Time.current)
    end
  end

  test '#each_iteration, creates the smoothed trend with the new ohlc' do
    range = Ohlc::Range.new('P1D', Time.current)
    asset_pair = AssetPair.new
    ohlc = Ohlc.new

    OhlcService.stubs(:call).with(range:, asset_pair:).returns(ohlc)
    SmoothedTrendService.expects(:call).with(ohlc)

    OhlcJob.new.each_iteration(range, { asset_pair: })
  end
end
