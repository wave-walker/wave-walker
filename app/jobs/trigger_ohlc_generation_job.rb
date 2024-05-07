# frozen_string_literal: true

class TriggerOhlcGenerationJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :low

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(
      AssetPair.where.not(imported_until: nil),
      cursor:
    )
  end

  def each_iteration(asset_pair)
    Ohlc.durations.each do |duration|
      OhlcJob.perform_later(asset_pair:, duration:)
    end
  end
end
