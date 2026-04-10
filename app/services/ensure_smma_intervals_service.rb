# frozen_string_literal: true

class EnsureSmmaIntervalsService
  def self.call(**) = new(**).call

  def initialize(strategy:)
    @strategy = strategy
  end

  def call
    AssetPair.importing.find_each do |asset_pair|
      Ohlc.durations.each do |duration|
        compute_missing_smmmas(asset_pair:, duration:)
      end
    end
  end

  private

  attr_reader :strategy

  def compute_missing_smmmas(asset_pair:, duration:)
    Ohlc.where(asset_pair:).by_duration(duration).order(:range_position).find_each do |ohlc|
      [strategy.fast_interval, strategy.slow_interval].each do |interval|
        next if SmoothedMovingAverage.exists?(
          asset_pair_id: ohlc.asset_pair_id,
          iso8601_duration: ohlc.iso8601_duration,
          range_position: ohlc.range_position,
          interval: interval.to_s
        )

        SmoothedMovingAverageService.call(ohlc:, interval:)
      end
    end
  end
end
