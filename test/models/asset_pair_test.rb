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
end
