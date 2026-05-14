# frozen_string_literal: true

require 'test_helper'

class SmoothedMovingAverageTest < ActiveSupport::TestCase
  test '.create_initial_sma returns nil when not enough OHLCs exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 2.days
    interval = 3

    result = SmoothedMovingAverage.create_initial_sma(asset_pair:, duration:, interval:)

    assert_nil result
  end

  test '.create_initial_sma calculates correct SMA value' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    interval = 5

    sma = SmoothedMovingAverage.create_initial_sma(asset_pair:, duration:, interval:)

    # Expected calculation:
    # OHLCs from range_position 19327 to 19331 (5 OHLCs)
    # atom20221201: hl2 = (10.5699 + 10.1432) / 2 = 10.35655
    # atom20221202: hl2 = (10.3772 + 10.1234) / 2 = 10.2503
    # atom20221203: hl2 = (10.4088 + 9.9905) / 2 = 10.19965
    # atom20221204: hl2 = (10.2816 + 10.033) / 2 = 10.1573
    # atom20221205: hl2 = (10.5662 + 10.1322) / 2 = 10.3492
    # SMA = (10.35655 + 10.2503 + 10.19965 + 10.1573 + 10.3492) / 5 = 10.2626
    expected_sma = 10.2626
    assert_in_delta expected_sma, sma.value, 0.0001
  end

  test '.create_initial_sma rounds to asset pair cost_decimals' do
    asset_pair = asset_pairs(:atomusd)
    asset_pair.update!(cost_decimals: 2)
    duration = 1.day
    interval = 5

    result = SmoothedMovingAverage.create_initial_sma(asset_pair:, duration:, interval:)

    assert_equal 2, result.value.to_s.split('.').last.length
  end

  test '.bulk_create creates initial SMA and subsequent SMMAs when no SMMAs exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    interval = 3

    smma_count = Ohlc.where(asset_pair: asset_pair).by_duration(duration).count - (interval - 1)

    assert_difference lambda {
      SmoothedMovingAverage.where(asset_pair:, interval:).by_duration(duration).count
    }, smma_count do
      SmoothedMovingAverage.bulk_create(asset_pair: asset_pair, duration: duration, interval: interval)
    end
  end

  test '.bulk_create starts from next range_position after latest_range_position when some SMMAs exist' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    interval = 3

    SmoothedMovingAverage.bulk_create(asset_pair: asset_pair, duration: duration, interval: interval)
    SmoothedMovingAverage.where(asset_pair:, interval:).by_duration(duration).order(range_position: :desc).limit(2)
                         .delete_all

    assert_difference -> { SmoothedMovingAverage.where(asset_pair:, interval:).by_duration(duration).count }, 2 do
      SmoothedMovingAverage.bulk_create(asset_pair: asset_pair, duration: duration, interval: interval)
    end
  end

  test '.bulk_create calculates mathematically correct SMMA values (SMA for first, SMMA formula for subsequent)' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day
    interval = 3

    SmoothedMovingAverage.bulk_create(asset_pair: asset_pair, duration: duration, interval: interval)
    sma, smma1, smma2 = SmoothedMovingAverage.where(asset_pair:, interval:).by_duration(duration).order(:range_position)
                                             .take(3)

    # Expected calculation:
    # OHLCs from range_position 19327 to 19331 (3 OHLCs)
    # atom20221201: hl2 = (10.5699 + 10.1432) / 2 = 10.35655
    # atom20221202: hl2 = (10.3772 + 10.1234) / 2 = 10.2503
    # atom20221203: hl2 = (10.4088 + 9.9905) / 2 = 10.19965
    # atom20221204: hl2 = (10.2816 + 10.033) / 2 = 10.1573
    # atom20221205: hl2 = (10.5662 + 10.1322) / 2 = 10.3492
    # SMA = (10.35655 + 10.2503 + 10.19965) / 3 = 10.26883
    # SMMA1 = (10.26883 * (3-1) + 10.1573) / 3 = 10.23165
    # SMMA2 = (10.23165 * (3-1) + 10.3492) / 3 = 10.27083
    assert_in_delta 10.26883, sma.value, 0.00001
    assert_in_delta 10.23165, smma1.value, 0.00001
    assert_in_delta 10.27083, smma2.value, 0.00001
  end

  test '.bulk_create works with different durations and intervals' do
    asset_pair = asset_pairs(:atomusd)
    duration = 2.days
    interval = 10

    assert_difference -> { SmoothedMovingAverage.where(asset_pair:, interval:).by_duration(duration).count } do
      SmoothedMovingAverage.bulk_create(asset_pair: asset_pair, duration: duration, interval: interval)
    end
  end
end
