class Asset < ApplicationRecord
  has_many :trades, dependent: :restrict_with_error

  after_create :add_trade_partition_for_asset

  def sync_trades
    trades_params = Kraken.trades(pair: default_trading_pair, since: last_synced_trade_at)
      .fetch(default_trading_pair).map do |price, volume, created_at, _buy_sell, _market_limit, _misc, kraken_id|
        created_at = Time.zone.at(created_at.to_f)

        {
          asset_id: id,
          price: price,
          volume: volume,
          created_at: created_at,
          id: kraken_id
        }
      end

    ActiveRecord::Base.transaction do
      Trade.upsert_all(trades_params)
      update!(last_synced_trade_at: trades_params.last[:created_at])
    end
  end

  private

  def default_trading_pair = "#{name}USD"

  def add_trade_partition_for_asset
    Trade.create_partition_for_asset(id, name)
  end
end
