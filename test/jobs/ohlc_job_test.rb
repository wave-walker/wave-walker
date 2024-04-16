# frozen_string_literal: true

require 'test_helper'

class OhlcJobTest < ActiveJob::TestCase
  test '#good_job_concurrency_key, is unique for asset pair and duration' do
    asset_pair = asset_pairs(:atomusd)
    job = OhlcJob.perform_later(asset_pair: asset_pair, duration: 1.hour)

    assert_equal "OhlcJob-#{asset_pair.id}-3600", job.good_job_concurrency_key
  end

  test '#perform, creates the inital OHLC' do
    asset_pair = asset_pairs(:atomusd)
    asset_pair.update!(imported_until: Time.current)

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
      OhlcJob.perform_now(asset_pair:, duration: 1.hour)
    end
  end

  test '#each_iteration, creates the smoothed trend with the new ohlc' do
    range = OhlcRangeValue.at(duration: 1.hour, time: Time.current)
    asset_pair = AssetPair.new
    ohlc = Ohlc.new

    OhlcService.stubs(:call).with(range:, asset_pair:).returns(ohlc)
    SmoothedTrendService.expects(:call).with(ohlc)

    OhlcJob.new.each_iteration(range, { asset_pair: })
  end
end
