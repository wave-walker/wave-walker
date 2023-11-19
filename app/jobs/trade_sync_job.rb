class TradeSyncJob < ApplicationJob
  queue_as :default

  retry_on Kraken::RateLimitExceeded, wait: 5.seconds, attempts: 10

  def perform(asset_pair, cursor_position: nil)
    cursor_position ||= asset_pair.trades.maximum(:created_at)&.to_i || 0
    response = Kraken.trades(pair: asset_pair.name, since: cursor_position)

    trades = response.fetch(:trades).filter_map do |price, volume, time, buy_sell, market_limit, misc, id|
      next if id.zero?

      {
        asset_pair_id: asset_pair.id,
        price: price,
        volume: volume,
        action: parse_action(buy_sell),
        order_type: parse_order_type(market_limit),
        misc: misc,
        created_at: Time.zone.at(time.to_f),
        id: id
      }
    end

    ActiveRecord::Base.transaction do
      Trade.upsert_all(trades)
      asset_pair.trades_count += trades.size

      if trades.size == 1000
        self.class.perform_later(asset_pair, cursor_position: response.fetch(:last))
      else
        asset_pair.imported!
        AssetPair.import_waiting_later
      end
    end

  end

  private

  def parse_action(buy_sell)
    raise "Invalid action" unless %w[b s].include?(buy_sell)

    buy_sell == "b" ? "buy" : "sell"
  end

  def parse_order_type(market_limit)
    raise "Invalid order type" unless %w[m l].include?(market_limit)

    market_limit == "m" ? "market" : "limit"
  end
end
