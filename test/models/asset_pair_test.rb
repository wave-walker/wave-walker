# frozen_string_literal: true

require 'test_helper'

class AssetPairTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test '#start_import, enqueues a job to import trades' do
    assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:atomusd)]) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_status }, to: 'importing' do
        asset_pairs(:atomusd).start_import
      end
    end
  end

  test '#start_import, raises an error if already importing' do
    asset_pairs(:atomusd).update!(import_status: :importing)

    error = assert_raises RuntimeError, 'Already importing!' do
      asset_pairs(:atomusd).start_import
    end

    assert_equal 'Already importing!', error.message
  end

  test '#start_import, change to waiting when another token is importing' do
    asset_pairs(:btcusd).importing!

    assert_no_enqueued_jobs(only: TradeSyncJob) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_status }, to: 'waiting' do
        asset_pairs(:atomusd).start_import
      end
    end
  end

  test '#finish_import,  imports the next waiting asset pair' do
    asset_pairs(:atomusd).importing!
    asset_pairs(:btcusd).waiting!

    assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:btcusd)]) do
      assert_changes -> { asset_pairs(:btcusd).reload.import_status }, to: 'importing' do
        asset_pairs(:atomusd).finish_import
      end
    end
  end

  test '#finish_import, enqueues new OHLC creation' do
    freeze_time

    asset_pairs(:atomusd).importing!

    generate_new_later = Minitest::Mock.new
    generate_new_later.expect(:call, nil, [asset_pairs(:atomusd), 1.minute.ago])

    Ohlc.stub(:generate_new_later, generate_new_later) do
      asset_pairs(:atomusd).finish_import
    end

    assert_mock generate_new_later
  end
end
