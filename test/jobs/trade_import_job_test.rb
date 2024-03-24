# frozen_string_literal: true

require 'test_helper'

class TradeImportJobTest < ActiveJob::TestCase
  setup do
    Trade.create_partition_for_asset(asset_pairs(:atomusd).id, asset_pairs(:atomusd).name)
  end

  test '#perfrom, should import trades with correct params' do
    asset_pair = asset_pairs(:atomusd)
    trades = [Kraken::Trade.new(1, 2, 3, 's', 'l', 'foo bar', 7)]

    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 0).returns(trades:, last: 1)
    Kraken.expects(:trades).with(pair: 'ATOMUSD', since: 1).returns(trades: [], last: 2)

    assert_difference 'asset_pair.trades.count', 1 do
      TradeImportJob.perform_now(asset_pair)
    end

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
    Kraken.stub(:trades, ->(_) { raise Kraken::RateLimitExceeded }) do
      assert_enqueued_with(job: TradeImportJob, args: [asset_pairs(:atomusd)]) do
        TradeImportJob.perform_now(asset_pairs(:atomusd))
      end
    end
  end

  test 'build_enumerator, sets no cursor if no previous trades exsite' do
    asset_pair = asset_pairs(:atomusd)

    KrakenTradesEnumerator.expects(:call).with(asset_pair, cursor: nil)

    TradeImportJob.new.build_enumerator(asset_pair, cursor: nil)
  end

  test 'build_enumerator, sets cursor if previous trades exsite' do
    asset_pair = asset_pairs(:atomusd)
    traded_at = 1.month.ago

    Trade.create!(
      id: [asset_pair.id, 1],
      price: 1,
      volume: 1,
      action: 'buy',
      order_type: 'market',
      misc: 'foo bar',
      created_at: traded_at
    )

    KrakenTradesEnumerator.expects(:call).with do |record, args|
      assert_equal record, asset_pair
      assert_in_delta args.fetch(:cursor), traded_at, 0.1.seconds
    end

    TradeImportJob.new.build_enumerator(asset_pair, cursor: nil)
  end

  # I guess this trades are not valid ... I need to check this
  test '#each_iteration, should skip trades without a id' do
    asset_pair = asset_pairs(:atomusd)
    trades = [Kraken::Trade.new(1, 2, 3, 's', 'l', 'foo bar', 0)]

    assert_no_changes -> { Trade.count } do
      TradeImportJob.new.each_iteration(trades, asset_pair)
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
      TradeImportJob.new.each_iteration(trades, asset_pair)
    end
  end
end
