# frozen_string_literal: true

class TriggerOhlcGenerationJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :default

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(
      AssetPair.where.not(imported_until: nil),
      cursor:
    )
  end

  def each_iteration(asset_pair)
    Ohlc.timeframes.each_key do |timeframe|
      OhlcJob.perform_later(asset_pair:, timeframe:)
    end
  end
end
