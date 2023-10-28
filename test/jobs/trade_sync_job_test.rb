require "test_helper"

class TradeSyncJobTest < ActiveJob::TestCase
  setup do
    Trade.create_partition_for_asset(asset_pairs(:atomusd).id, asset_pairs(:atomusd).name)
  end

  test "should sync a trade with correct params" do
    Kraken.stub(:trades, { trades: [[1, 2, 3, "s", "l", "foo bar", 7]], last: 1 }) do
      TradeSyncJob.perform_now(asset_pairs(:atomusd))
      trade = Trade.find_by!(asset_pair_id: asset_pairs(:atomusd).id, id: 7)

      assert_equal asset_pairs(:atomusd).id, trade.asset_pair_id
      assert_equal 1, trade.price
      assert_equal 2, trade.volume
      assert_equal Time.zone.at(3), trade.created_at
      assert_equal "sell", trade.action
      assert_equal "limit", trade.order_type
      assert_equal "foo bar", trade.misc
    end
  end

  test "should sync 1000 trades and should schedule follow up sync" do
    Kraken.stub(:trades, { trades: Array.new(1000) {|i| [1, 1, 1, "b", "m", "", i] }, last: 1 }) do
      assert_changes -> { Trade.count }, from: 0, to: 1000 do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should schedule follow up sync when remaining trades exsiote" do
    Kraken.stub(:trades, { trades: Array.new(1000) {|i| [1, 1, 1, "b", "m", "", i] }, last: 1 }) do
      assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:atomusd)]) do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should not schedule follow up sync when remaining trades do not exist" do
    Kraken.stub(:trades, { trades: Array.new(999) {|i| [1, 1, 1, "b", "m", "", i] }, last: 1 }) do
      assert_no_enqueued_jobs do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should end importing when remaining trades do not exist" do
    Kraken.stub(:trades, { trades: Array.new(1) {|i| [1, 1, 1, "b", "m", "", i] }, last: 123456 }) do
      asset_pairs(:atomusd).update!(importing: true)

      assert_changes -> { asset_pairs(:atomusd).reload.importing }, from: true, to: false do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should update the cursor position" do
    Kraken.stub(:trades, { trades: Array.new(1) {|i| [1, 1, 1, "b", "m", "", i] }, last: 123456 }) do
      assert_changes -> { asset_pairs(:atomusd).reload.kraken_cursor_position }, from: 0, to: 123456 do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
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
      TradeSyncJob.perform_now(asset_pairs(:atomusd))
    end
  end

  test "should retry on Kraken::TooManyRequests" do
    Kraken.stub(:trades, -> (_) { raise Kraken::RateLimitExceeded }) do
      assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:atomusd)]) do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end
end
