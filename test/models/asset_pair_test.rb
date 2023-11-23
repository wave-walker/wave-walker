require "test_helper"

class AssetPairTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#start_import, enqueues a job to import trades" do
    assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:atomusd)]) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_status }, to: 'importing' do
        asset_pairs(:atomusd).start_import
      end
    end
  end

  test "#start_import, raises an error if already importing" do
    asset_pairs(:atomusd).update!(import_status: :importing)

    error = assert_raises RuntimeError, "Already importing!" do
      asset_pairs(:atomusd).start_import
    end

    assert_equal "Already importing!", error.message
  end

  test "#start_import, change to waiting when another token is importing" do
    asset_pairs(:btcusd).importing!

    assert_no_enqueued_jobs(only: TradeSyncJob) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_status }, to: 'waiting' do
        asset_pairs(:atomusd).start_import
      end
    end
  end

  test "#finish_import,  imports the next waiting asset pair" do
    asset_pairs(:atomusd).importing!
    asset_pairs(:btcusd).waiting!

    assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:btcusd)]) do
      assert_changes -> { asset_pairs(:btcusd).reload.import_status }, to: 'importing' do
        asset_pairs(:atomusd).finish_import
      end
    end
  end
end
