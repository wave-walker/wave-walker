# frozen_string_literal: true

require 'test_helper'

class OhlcJobTest < ActiveJob::TestCase
  test '#concurrency_key, is unique for asset pair and duration' do
    asset_pair = asset_pairs(:atomusd)
    job = OhlcJob.perform_later(asset_pair:, duration: 1.hour)

    assert_equal "OhlcJob/#{asset_pair.id}-3600", job.concurrency_key
  end

  test '#perform, creates the inital OHLC' do
    asset_pair = asset_pairs(:atomusd)
    asset_pair.update!(imported_until: Time.current)

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
      assert_enqueued_with(
        job: CreateSmoothedTrendsJob,
        args: [{ asset_pair:, duration: 1.hour }]
      ) do
        OhlcJob.perform_now(asset_pair:, duration: 1.hour)
      end
    end
  end

  test '#on_complete, enqueues create smoothed trends job' do
    asset_pair = asset_pairs(:atomusd)
    range = OhlcRangeValue.at(duration: 1.hour, time: Time.current)
    enumerator = [[[range], range.next.position]].to_enum

    OhlcRangesEnumerator.stubs(:call).returns(enumerator)
    OhlcService.stubs(:call)

    assert_enqueued_with(
      job: CreateSmoothedTrendsJob,
      args: [{ asset_pair:, duration: 1.hour }]
    ) do
      OhlcJob.perform_now(asset_pair:, duration: 1.hour)
    end
  end
end
