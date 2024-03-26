# frozen_string_literal: true

require 'test_helper'

class AssetPairSyncJobTest < ActiveJob::TestCase
  test 'starts importing marked asset pairs' do
    atom_usd = asset_pairs(:atomusd)
    btc_usd = asset_pairs(:btcusd)

    atom_usd.import

    assert_not btc_usd.importing?

    assert_enqueued_jobs 1 do
      AssetPairSyncJob.perform_now
    end

    assert_enqueued_with(job: TradeImportJob, args: [atom_usd])
  end
end
