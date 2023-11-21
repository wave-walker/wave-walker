require "test_helper"

class AssetPairTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#import_later, enqueues a job to import trades" do
    assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:atomusd)]) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_state }, to: 'importing' do
        asset_pairs(:atomusd).import_later
      end
    end
  end

  test "#import_later, raises an error if already importing" do
    asset_pairs(:atomusd).update!(import_state: :importing)

    error = assert_raises RuntimeError, "Already importing!" do
      asset_pairs(:atomusd).import_later
    end

    assert_equal "Already importing!", error.message
  end

  test "#import_later, change to waiting when another token is importing" do
    asset_pairs(:btcusd).importing!

    assert_no_enqueued_jobs(only: TradeSyncJob) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_state }, to: 'waiting' do
        asset_pairs(:atomusd).import_later
      end
    end
  end

  test ".import_waiting_later, imports the next waiting asset pair" do
    asset_pairs(:atomusd).waiting!
    asset_pairs(:btcusd).waiting!

    assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:btcusd)]) do
      assert_changes -> { asset_pairs(:btcusd).reload.import_state }, to: 'importing' do
        AssetPair.import_waiting_later
      end
    end
  end
end
