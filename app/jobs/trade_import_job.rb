# frozen_string_literal: true

class TradeImportJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency
  include JobIteration::Iteration

  queue_as :default

  retry_on Kraken::RateLimitExceeded, wait: 5.seconds, attempts: 10

  good_job_control_concurrency_with(total_limit: 1)

  def build_enumerator(cursor:)
    enumerator_builder.nested(
      [
        ->(asser_cursor) { enumerator_builder.active_record_on_records(AssetPair.importing, cursor: asser_cursor) },
        ->(asset_pair, trades_cursor) { KrakenTradesEnumerator.call(asset_pair, cursor: trades_cursor) }
      ],
      cursor:
    )
  end

  def each_iteration(args)
    asset_pair = args.fetch(:asset_pair)
    trades = args.fetch(:trades)

    trades_params = trades.reject { |trade| trade.id.zero? }
                          .map { |trade| trade.to_h.merge(asset_pair_id: asset_pair.id) }

    ActiveRecord::Base.transaction do
      asset_pair.update!(imported_until: Time.current)
      Trade.upsert_all(trades_params) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
