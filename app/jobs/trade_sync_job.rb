# frozen_string_literal: true

class TradeSyncJob < ApplicationJob
  queue_as :default

  retry_on Kraken::RateLimitExceeded, wait: 5.seconds, attempts: 10

  # rubocop:todo Metrics/MethodLength
  def perform(asset_pair, cursor_position: nil) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    cursor_position ||= asset_pair.trades.maximum(:created_at).to_i
    response = Kraken.trades(pair: asset_pair.name, since: cursor_position)

    trades = response.fetch(:trades)
                     .reject { |trade| trade.id.zero? }
                     .map { |trade| trade.to_h.merge(asset_pair_id: asset_pair.id) }

    ActiveRecord::Base.transaction do
      Trade.upsert_all(trades) # rubocop:todo Rails/SkipsModelValidations

      if trades.size == 1000
        self.class.perform_later(asset_pair, cursor_position: response.fetch(:last))
        AssetPair.increment_counter(:trades_count, asset_pair, by: 1000) # rubocop:todo Rails/SkipsModelValidations
      else
        asset_pair.finish_import
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
