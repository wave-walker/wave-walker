require "test_helper"

class TradeSyncJobTest < ActiveJob::TestCase
  setup do
    Trade.create_partition_for_asset(assets(:atom).id, assets(:atom).name)
  end

  test "should sync 1000 trades and should schedule follow up sync" do
    assert_changes -> { Trade.count }, from: 0, to: 1000 do
      assert_enqueued_with(job: TradeSyncJob, args: [assets(:atom)]) do
        assert_changes -> { assets(:atom).reload.kraken_cursor_position }, from: 0, to: 1555997384703315580 do
          TradeSyncJob.perform_now(assets(:atom))
        end
      end
    end
  end
end
