# frozen_string_literal: true

class TradeImportJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  include JobIteration::Iteration

  queue_as :default

  retry_on Kraken::RateLimitExceeded, wait: 5.seconds, attempts: 10

  on_complete do |job|
    OhlcJob.enqueue_for_all_timeframes(job.arguments.first, 3.seconds.ago)
  end

  good_job_control_concurrency_with(perform_limit: 1)

  def build_enumerator(asset_pair, cursor:)
    cursor ||= asset_pair.trades.maximum(:created_at)
    KrakenTradesEnumerator.call(asset_pair, cursor:)
  end

  def each_iteration(trades, asset_pair)
    trades_params = trades.reject { |trade| trade.id.zero? }
                          .map { |trade| trade.to_h.merge(asset_pair_id: asset_pair.id) }

    Trade.upsert_all(trades_params) # rubocop:disable Rails/SkipsModelValidations
  end
end
