# frozen_string_literal: true

require 'test_helper'

class OhlcTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    Trade.create_partition_for_asset(asset_pairs(:atomusd).id, asset_pairs(:atomusd).name)
  end

  test '.last_end_at, returns the last end_at for the given asset_pair and timeframe' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = :PT1H

    current_range = Ohlc::Range.new(timeframe, Time.current)

    Trade.create!(id: [asset_pair.id, 1], price: 1, volume: 1, action: :buy, order_type: :market, misc: '')

    assert_equal current_range.begin, Ohlc.last_end_at(asset_pair, timeframe)

    Ohlc.create!(asset_pair:, start_at: current_range.begin, timeframe:,
                 open: 1, high: 1, low: 1, close: 1, volume: 1)

    assert_equal current_range.end, Ohlc.last_end_at(asset_pair, timeframe)
  end

  test '.create_from_trades, when trades exists' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = :PT1H
    range = Ohlc::Range.new(timeframe, Time.current)

    Trade.create!(id: [asset_pair.id, 1], price: 3, volume: 1, action: :buy,
                  order_type: :market, misc: '', created_at: range.begin)

    Trade.create!(id: [asset_pair.id, 2], price: 1, volume: 2, action: :buy,
                  order_type: :market, misc: '', created_at: range.begin)

    Trade.create!(id: [asset_pair.id, 3], price: 5, volume: 3, action: :buy,
                  order_type: :market, misc: '', created_at: range.end - 1.minute)

    Trade.create!(id: [asset_pair.id, 4], price: 2, volume: 4, action: :buy,
                  order_type: :market, misc: '', created_at: range.begin.end_of_hour)

    ohlc = Ohlc.create_from_trades(asset_pair, timeframe, range)

    assert_equal ohlc.high, 5
    assert_equal ohlc.low, 1
    assert_equal ohlc.open, 3
    assert_equal ohlc.close, 2
    assert_equal ohlc.volume, 10
    assert_equal ohlc.timeframe, 'PT1H'
    assert_equal ohlc.start_at, range.begin
  end

  test '.create_from_trades, when no trades exists' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = :PT1H
    range = Ohlc::Range.new(timeframe, Time.current)

    Ohlc.create!(asset_pair:, high: 1, low: 2, open: 3, close: 4, volume: 1,
                 timeframe:, start_at: range.begin)

    ohlc = Ohlc.create_from_trades(asset_pair, timeframe, range.next)

    assert_equal ohlc.high, 4
    assert_equal ohlc.low, 4
    assert_equal ohlc.open, 4
    assert_equal ohlc.close, 4
    assert_equal ohlc.volume, 0
    assert_equal ohlc.timeframe, 'PT1H'
    assert_equal ohlc.start_at, range.next.begin
  end

  test 'it enqueues analysation' do
    asset_pair = asset_pairs(:atomusd)
    timeframe = :PT1H
    range = Ohlc::Range.new(timeframe, Time.current)
    ohlc = Ohlc.new(asset_pair:, high: 1, low: 2, open: 3, close: 4, volume: 1,
                    timeframe:, start_at: range.begin)

    assert_enqueued_with(job: OhlcAnalyzeJob, args: [ohlc]) do
      ohlc.save!
    end
  end

  test '#previous_ohlcs, returns the previous ohlcs' do
    ohlc = ohlcs(:atom_2019_04_24) # rubocop:disable Naming/VariableNumber

    assert_equal ohlc.previous_ohlcs, [ohlcs(:atom_2019_04_23), ohlcs(:atom_2019_04_22)] # rubocop:disable Naming/VariableNumber
  end

  test '#hl2' do
    assert_equal Ohlc.new(high: 3, low: 2).hl2, 2.5
  end
end
