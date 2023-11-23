require "test_helper"

class TradeSyncJobTest < ActiveJob::TestCase
  setup do
    Trade.create_partition_for_asset(asset_pairs(:atomusd).id, asset_pairs(:atomusd).name)
  end

  test "should sync a trade with correct params" do
    Kraken.stub(:trades, { trades: [Kraken::Trade.new(1, 2, 3, "s", "l", "foo bar", 7)], last: 1 }) do
      assert_difference 'asset_pairs(:atomusd).reload.trades_count', 1 do
        perform_enqueued_jobs(only: TradeSyncJob) { asset_pairs(:atomusd).start_import }
      end

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
    Kraken.stub(:trades, { trades: Array.new(1000) {|i| Kraken::Trade.new(1, 1, 1, "b", "m", "", i + 1) }, last: 1 }) do
      assert_difference ['Trade.count', 'asset_pairs(:atomusd).reload.trades_count'], 1000 do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should schedule follow up sync when remaining trades exsiote" do
    Kraken.stub(:trades, { trades: Array.new(1000) {|i| Kraken::Trade.new(1, 1, 1, "b", "m", "", i + 1) }, last: 123456 }) do
      assert_enqueued_with(job: TradeSyncJob, args: [asset_pairs(:atomusd), { cursor_position: 123456 }]) do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should not schedule follow up sync when remaining trades do not exist" do
    asset_pairs(:atomusd).start_import

    Kraken.stub(:trades, { trades: Array.new(999) {|i| Kraken::Trade.new(1, 1, 1, "b", "m", "", i + 1) }, last: 1 }) do
      assert_no_enqueued_jobs do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should end importing when remaining trades do not exist" do
    asset_pairs(:atomusd).start_import

    Kraken.stub(:trades, { trades: Array.new(1) {|i| Kraken::Trade.new(1, 1, 1, "b", "m", "", i) }, last: 123456 }) do
      assert_changes -> { asset_pairs(:atomusd).reload.import_status }, to: 'imported' do
        TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test "should start importing other trades when finished" do
    asset_pairs(:atomusd).start_import
    asset_pairs(:btcusd).start_import

    Kraken.stub(:trades, { trades: Array.new(1) {|i| Kraken::Trade.new(1, 1, 1, "b", "m", "", i) }, last: 123456 }) do
      assert_changes -> { asset_pairs(:btcusd).reload.import_status }, to: 'importing' do
          TradeSyncJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  # I guess this trages are not valid ... I need to check this
  test "should skip trades without a id" do
    Kraken.stub(:trades, { trades: [Kraken::Trade.new(1, 2, 3, "s", "l", "foo bar", 0)], last: 1 }) do
      assert_no_changes -> { Trade.count } do
        perform_enqueued_jobs(only: TradeSyncJob) { asset_pairs(:atomusd).start_import }
      end
    end
  end

  test "should request trades for the atom token" do
    asset_pairs(:atomusd).importing!

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
