# frozen_string_literal: true

require 'test_helper'

class TriggerOhlcGenerationJobTest < ActiveJob::TestCase
  test 'enqueus OHLC creation for all assert paris' do
    timeframes = Ohlc.timeframes.keys
    atomusd = asset_pairs(:atomusd)
    btcusd = asset_pairs(:btcusd)
    atomusd.update!(imported_until: Time.current)
    btcusd.update!(imported_until: Time.current)

    TriggerOhlcGenerationJob.perform_now

    timeframes.each do |timeframe|
      assert_enqueued_with(job: OhlcJob, args: [{ asset_pair: atomusd, timeframe: }])
      assert_enqueued_with(job: OhlcJob, args: [{ asset_pair: btcusd, timeframe: }])
    end
  end

  test 'dose not enuqueue OHLC creation for assets have no imports' do
    asset_pairs(:atomusd)
    asset_pairs(:btcusd)

    assert_no_enqueued_jobs do
      TriggerOhlcGenerationJob.perform_now
    end
  end
end
