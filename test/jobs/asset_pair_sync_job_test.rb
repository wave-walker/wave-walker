# frozen_string_literal: true

require 'test_helper'

class AssetPairSyncJobTest < ActiveJob::TestCase
  test 'start import of synced assets' do
    atom_usd = asset_pairs(:atomusd)
    btc_usd = asset_pairs(:btcusd)

    atom_usd.imported!
    btc_usd.imported!

    assert_changes('AssetPair.where(import_status: [:importing, :waiting]).count', 2) do
      assert_enqueued_with(job: TradeImportJob) do
        AssetPairSyncJob.perform_now
      end
    end
  end

  test 'dose not import unsynced asset pairs' do
    atom_usd = asset_pairs(:atomusd)
    atom_usd.pending!

    assert_no_changes('atom_usd.reload.import_status') do
      AssetPairSyncJob.perform_now
    end
  end
end
