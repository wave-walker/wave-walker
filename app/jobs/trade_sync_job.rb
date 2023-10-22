class TradeSyncJob < ApplicationJob
  queue_as :default

  def perform(asset)
    response = Kraken.trades(pair: asset.usd_trading_pair, since: asset.kraken_cursor_position)

    trades = response.fetch(:trades).map do |price, volume, time, _buy_sell, _market_limit, _misc, id|
      {
        asset_id: asset.id,
        price: price,
        volume: volume,
        created_at: Time.zone.at(time.to_f),
        id: id
      }
    end

    ActiveRecord::Base.transaction do
      Trade.insert_all!(trades)
      asset.update!(kraken_cursor_position: response.fetch(:last))
    end

    self.class.perform_later(asset) if trades.size == 1000
  end
end
