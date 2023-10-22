require "test_helper"

class TradeSyncJobTest < ActiveJob::TestCase
  setup do
    Trade.create_partition_for_asset(assets(:atom).id, assets(:atom).name)
  end

  test "should sync 1000 trades and should schedule follow up sync" do
    Kraken.stub(:trades, { trades: Array.new(1000) {|i| [1, 1, 1, 1, 1, 1, i] }, last: 1 }) do
      assert_changes -> { Trade.count }, from: 0, to: 1000 do
        TradeSyncJob.perform_now(assets(:atom))
      end
    end
  end

  test "should schedule follow up sync when remaining trades exsiote" do
    Kraken.stub(:trades, { trades: Array.new(1000) {|i| [1, 1, 1, 1, 1, 1, i] }, last: 1 }) do
      assert_enqueued_with(job: TradeSyncJob, args: [assets(:atom)]) do
        TradeSyncJob.perform_now(assets(:atom))
      end
    end
  end

  test "should not schedule follow up sync when remaining trades do not exist" do
    Kraken.stub(:trades, { trades: Array.new(999) {|i| [1, 1, 1, 1, 1, 1, i] }, last: 1 }) do
      assert_no_enqueued_jobs do
        TradeSyncJob.perform_now(assets(:atom))
      end
    end
  end

  test "should update the cursor position" do
    Kraken.stub(:trades, { trades: Array.new(1) {|i| [1, 1, 1, 1, 1, 1, i] }, last: 123456 }) do
      assert_changes -> { assets(:atom).reload.kraken_cursor_position }, from: 0, to: 123456 do
        TradeSyncJob.perform_now(assets(:atom))
      end
    end
  end

  test "should request trades for the atom token" do
    args_check = -> (args) {
      assert_equal "ATOMUSD", args[:pair]
      assert_equal 0, args[:since]
      { trades: [], last: 0 }
    }

    Kraken.stub(:trades, args_check) do
      TradeSyncJob.perform_now(assets(:atom))
    end
  end
end
