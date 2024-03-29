# frozen_string_literal: true

require 'test_helper'

class TriggerOhlcGenerationJobTest < ActiveJob::TestCase
  test 'enqueus OHLC creation for all assert paris' do
    timeframes = Ohlc.timeframes.keys
    atomusd = asset_pairs(:atomusd)
    btcusd = asset_pairs(:btcusd)

    TriggerOhlcGenerationJob.perform_now

    timeframes.each do |timeframe|
      assert_enqueued_with(job: OhlcJob, args: [{ asset_pair: atomusd, timeframe: }])
      assert_enqueued_with(job: OhlcJob, args: [{ asset_pair: btcusd, timeframe: }])
    end
  end
end
