# frozen_string_literal: true

require 'test_helper'

class AssetPairTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '#import' do
    asset_pair = asset_pairs(:btcusd)

    assert_changes -> { asset_pair.reload.importing? }, to: true do
      asset_pair.import
    end
  end

  test '#after_create, creates backtests for each timeframe' do
    assert_changes 'Backtest.count', 6 do
      AssetPair.create!(
        name: 'FOOUSD',
        name_on_exchange: 'FOOXDS',
        importing: false,
        base: 'FOO',
        quote: 'ZUSD',
        cost_decimals: 3
      )
    end
  end

  test 'partition creation' do
    partitions = %w[
      asset_pair_999_ohlcs
      asset_pair_999_smoothed_moving_averages
      asset_pair_999_smoothed_trends
      asset_pair_999_trades
    ]

    current_tables = ActiveRecord::Base.connection.tables.sort

    assert_changes -> { ActiveRecord::Base.connection.tables.sort - current_tables }, from: [], to: partitions do
      AssetPair.create!(
        id: 999,
        name: 'FOOBAR',
        name_on_exchange: 'FOOBAR',
        base: 'foo',
        quote: 'bar',
        cost_decimals: 8
      )
    end

    assert_changes -> { ActiveRecord::Base.connection.tables.sort - current_tables }, from: partitions, to: [] do
      AssetPair.find(999).destroy
    end
  end
end
