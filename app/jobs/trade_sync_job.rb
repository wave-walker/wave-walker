class TradeSyncJob < ApplicationJob
  queue_as :default

  retry_on Kraken::RateLimitExceeded, wait: 5.seconds, attempts: 10

  def perform(asset_pair, cursor_position: nil)
    cursor_position ||= asset_pair.trades.maximum(:created_at).to_i
    response = Kraken.trades(pair: asset_pair.name, since: cursor_position)

    trades = response.fetch(:trades)
      .select {|trade| !trade.id.zero? }
      .map {|trade| trade.to_h.merge(asset_pair_id: asset_pair.id) }

    ActiveRecord::Base.transaction do
      Trade.upsert_all(trades)
      asset_pair.trades_count += trades.size

      if trades.size == 1000
        asset_pair.save!
        self.class.perform_later(asset_pair, cursor_position: response.fetch(:last))
      else
        asset_pair.finish_import
      end
    end
  end
end
