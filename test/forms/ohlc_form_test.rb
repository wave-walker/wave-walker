require "test_helper"

class OhlcFormTest < ActiveSupport::TestCase
  setup do
    Trade.create_partition_for_asset(asset_pairs(:atomusd).id, asset_pairs(:atomusd).name)
  end

  test "should create OHLC with trades in timeframe" do
    freeze_time

    asset_pair = asset_pairs(:atomusd)
    range = Ohlc::Range.new('PT1H', 1.hour.ago)

    Trade.create!(id: [asset_pair.id, 1], price: 1, volume: 1, created_at: range.first - 1.second,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 2], price: 3, volume: 2, created_at: range.first,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 3], price: 2, volume: 3, created_at: range.first + 15.minutes,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 4], price: 5, volume: 4, created_at: range.first + 45.minutes,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 5], price: 4, volume: 5, created_at: range.end - 1.second,
                  action: :buy, order_type: :limit, misc: '')

    Trade.create!(id: [asset_pair.id, 6], price: 6, volume: 6, created_at: range.end,
                  action: :buy, order_type: :limit, misc: '')

    ohlc = OhlcForm.new(asset_pair:, range:).save

    assert_equal 1.hour.ago.beginning_of_hour, ohlc.start_at
    assert_equal 'PT1H', ohlc.timeframe
    assert_equal 3, ohlc.open
    assert_equal 5, ohlc.high
    assert_equal 2, ohlc.low
    assert_equal 4, ohlc.close
    assert_equal 14, ohlc.volume
    assert_equal asset_pair, ohlc.asset_pair
  end

  test "should not create OHLC without trades in timeframe" do
    asset_pair = asset_pairs(:atomusd)
    range = Ohlc::Range.new('PT1H', 1.hour.ago)

    ohlc = OhlcForm.new(asset_pair:, range:).save

    assert_not ohlc
  end
end
