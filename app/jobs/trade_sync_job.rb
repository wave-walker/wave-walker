class TradeSyncJob < ApplicationJob
  queue_as :default

  retry_on Kraken::RateLimitExceeded, wait: 5.seconds, attempts: 10

  def perform(asset_pair)
    response = Kraken.trades(pair: asset_pair.name, since: asset_pair.kraken_cursor_position)

    trades = response.fetch(:trades).map do |price, volume, time, buy_sell, market_limit, misc, id|
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
      asset_pair.kraken_cursor_position = response.fetch(:last)

      if trades.size == 1000
        self.class.perform_later(asset_pair)
      else
        asset_pair.importing = false
      end
      asset_pair.save!
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
