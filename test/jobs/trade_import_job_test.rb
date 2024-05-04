# frozen_string_literal: true

require 'test_helper'
require 'job-iteration/test_helper'

class TradeImportJobTest < ActiveJob::TestCase
  include JobIteration::TestHelper

  setup do
    KrakenTradesEnumerator.reset_load_trades_limit!
  end

  test '#perform, should import trades for all imorting asset_pairs' do
    asset_pairs(:btcusd).update!(importing: true)

    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 0).returns(trades: [], last: 1)
    Kraken.expects(:trades).with(pair: 'XBTUSD', since: 0).returns(trades: [], last: 1)

    TradeImportJob.perform_now
  end

  test '#perfrom, should import trades with correct params' do
    asset_pair = asset_pairs(:atomusd)
    trades = [Kraken::Trade.new(1, 2, 3, 's', 'l', 'foo bar', 7)]

    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 0).returns(trades:, last: 1)
    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 1).returns(trades: [], last: 2)

    assert_changes(-> { asset_pair.trades.count }, 1) { TradeImportJob.perform_now }

    trade = Trade.find_by!(asset_pair_id: asset_pairs(:atomusd).id, id: 7)

    assert_equal asset_pairs(:atomusd).id, trade.asset_pair_id
    assert_equal 1, trade.price
    assert_equal 2, trade.volume
    assert_equal Time.zone.at(3), trade.created_at
    assert_equal 'sell', trade.action
    assert_equal 'limit', trade.order_type
    assert_equal 'foo bar', trade.misc
  end

  test '#perform, should retry on Kraken::TooManyRequests' do
    Kraken.stubs(:trades).raises(Kraken::RateLimitExceeded)

    assert_enqueued_with(job: TradeImportJob) do
      TradeImportJob.perform_now
    end
  end

  # I guess this trades are not valid ... I need to check this
  test '#each_iteration, should skip trades without a id' do
    asset_pair = asset_pairs(:atomusd)
    trades = [Kraken::Trade.new(1, 2, 3, 's', 'l', 'foo bar', 0)]

    assert_no_changes -> { Trade.count } do
      TradeImportJob.new.each_iteration({ trades:, asset_pair: })
    end
  end

  test '#each_iteration, should skip trades with an id that already exists' do
    asset_pair = asset_pairs(:atomusd)

    Trade.create!(
      id: [asset_pair.id, 1],
      price: 1,
      volume: 1,
      action: 'buy',
      order_type: 'market',
      misc: 'foo bar'
    )

    trades = [
      Kraken::Trade.new(1, 2, 3, 's', 'l', 'foo bar', 1),
      Kraken::Trade.new(1, 2, 3, 's', 'l', 'foo bar', 2)
    ]

    assert_difference 'asset_pair.trades.count', 1 do
      TradeImportJob.new.each_iteration({ trades:, asset_pair: })
    end
  end

  test '#each_iteration, records the import progress' do
    freeze_time

    trades = [Kraken::Trade.new(1, 2, 3, 's', 'l', 'foo bar', 1)]
    asset_pair = asset_pairs(:atomusd)

    assert_changes -> { asset_pair.reload.imported_until }, to: Time.zone.at(3) do
      TradeImportJob.new.each_iteration({ trades:, asset_pair: })
    end
  end
end
