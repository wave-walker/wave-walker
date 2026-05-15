# frozen_string_literal: true

class OhlcAnalyzeJob < ApplicationJob
  def perform(asset_pair:, duration:)
    SmoothedMovingAverage.bulk_create(asset_pair:, duration:)
    SmoothedTrend.bulk_create_for_duration(asset_pair:, duration:)
  end
end
