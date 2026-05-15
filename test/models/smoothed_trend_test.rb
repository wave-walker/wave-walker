# frozen_string_literal: true

require 'test_helper'

class SmoothedTrendTest < ActiveSupport::TestCase
  test 'bulk_create passes params from NewSmoothedTendParameterQuery to insert_all!' do
    asset_pair = asset_pairs(:atomusd)
    duration = 1.day

    params = [
      { range_position: 100, asset_pair_id: asset_pair.id, iso8601_duration: 'P1D', trend: :bullish, flip: false,
        fast_smma: 10.0, slow_smma: 9.0 },
      { range_position: 101, asset_pair_id: asset_pair.id, iso8601_duration: 'P1D', trend: :neutral, flip: true,
        fast_smma: 9.0, slow_smma: 10.0 }
    ]

    query_stub = mock
    query_stub.expects(:in_batches).yields(params)
    NewSmoothedTendParameterQuery.expects(:new).with(asset_pair:, duration:).returns(query_stub)

    SmoothedTrend.expects(:insert_all!).with(params)

    SmoothedTrend.bulk_create(asset_pair:, duration:)
  end
end
