require "test_helper"

class AssetPairTest < ActiveSupport::TestCase
  test "#import_later, enqueues a job to import trades" do
    perform_later_mock = Minitest::Mock.new
    perform_later_mock.expect :call, nil, [asset_pairs(:atomusd)]

    TradeSyncJob.stub(:perform_later, perform_later_mock) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_state }, to: 'importing' do
        asset_pairs(:atomusd).import_later
      end
    end

    assert_mock perform_later_mock
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

    assert_changes -> { asset_pairs(:atomusd).reload.import_state }, to: 'waiting' do
      asset_pairs(:atomusd).import_later
    end
  end

  test ".import_waiting_later, imports the next waiting asset pair" do
    asset_pairs(:atomusd).waiting!
    asset_pairs(:btcusd).waiting!

    perform_later_mock = Minitest::Mock.new
    perform_later_mock.expect :call, nil, [asset_pairs(:btcusd)]

    TradeSyncJob.stub(:perform_later, perform_later_mock) do
      assert_changes -> { asset_pairs(:btcusd).reload.import_state }, to: 'importing' do
        AssetPair.import_waiting_later
      end
    end

    assert_mock perform_later_mock
  end
end
