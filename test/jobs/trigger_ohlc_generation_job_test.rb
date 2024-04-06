# frozen_string_literal: true

require 'test_helper'

class TriggerOhlcGenerationJobTest < ActiveJob::TestCase
  test 'enqueus OHLC creation for all assert paris' do
    durations = Ohlc.durations.keys
    atomusd = asset_pairs(:atomusd)
    btcusd = asset_pairs(:btcusd)
    atomusd.update!(imported_until: Time.current)
    btcusd.update!(imported_until: Time.current)

    TriggerOhlcGenerationJob.perform_now

    durations.each do |duration|
      assert_enqueued_with(job: OhlcJob, args: [{ asset_pair: atomusd, duration: }])
      assert_enqueued_with(job: OhlcJob, args: [{ asset_pair: btcusd, duration: }])
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
