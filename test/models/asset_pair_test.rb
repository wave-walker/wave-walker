require "test_helper"

class AssetPairTest < ActiveSupport::TestCase
  test "#import_later, enqueues a job to import trades" do
    perform_later_mock = Minitest::Mock.new
    perform_later_mock.expect :call, nil, [asset_pairs(:atomusd)]

    TradeSyncJob.stub(:perform_later, perform_later_mock) do
      assert_changes -> { asset_pairs(:atomusd).reload.importing }, to: true do
        asset_pairs(:atomusd).import_later
      end
    end

    assert_mock perform_later_mock
  end

  test "#import_later, raises an error if already importing" do
    asset_pairs(:atomusd).update!(importing: true)

    error = assert_raises RuntimeError, "Already importing!" do
      asset_pairs(:atomusd).import_later
    end

    assert_equal "Already importing!", error.message
  end
end
