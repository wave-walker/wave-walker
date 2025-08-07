# frozen_string_literal: true

class SmoothedMovingAverageService
  def self.call(**) = new(**).call

  def initialize(ohlc:, interval:)
    @ohlc = ohlc
    @interval = interval
  end

  def call
    return unless value

    SmoothedMovingAverage.create!(id: ohlc.id, interval:, value:)
  end

  private

  attr_reader :ohlc, :interval

  def decimals = ohlc.asset_pair.cost_decimals
  def value = (smma || sma)&.round(decimals)

  def smma
    return unless last_smma

    ((last_smma * (interval - 1)) + ohlc.hl2) / interval
  end

  def sma
    return if last_hl2s.count != interval

    last_hl2s.sum / interval
  end

  def last_smma
    @last_smma ||= SmoothedMovingAverage.by_duration(ohlc.duration).find_by(
      asset_pair_id: ohlc.asset_pair_id,
      range_position: ohlc.range_position - 1,
      interval:
    )&.value
  end

  def last_hl2s
    @last_hl2s ||= ohlc.previous_ohlcs.first(interval).map(&:hl2)
  end
end
