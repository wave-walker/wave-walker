# frozen_string_literal: true

require 'test_helper'

class OhlcTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '.generate_new_later, enqueues the OHLC for all timeframes' do
    last_imported_at = 1.minute.ago
    asset_pair = asset_pairs(:atomusd)
    timeframes = Ohlc.timeframes.keys

    timeframes.each do |timeframe|
      assert_enqueued_with(job: NewOhlcForTimeframeJob, args: [asset_pair, timeframe, last_imported_at]) do
        Ohlc.generate_new_later(asset_pair, last_imported_at)
      end
    end
  end
end
