# frozen_string_literal: true

require 'test_helper'

class OhlcStatusTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '#latest_range_position, returns the position of the newest OHLC' do
    asset_pair = asset_pairs(:atomusd)
    ohlc_status = OhlcStatus.find_by!(asset_pair:, iso8601_duration: 'P1D')

    assert_equal ohlc_status.latest_range_position, 19_447
  end
end
