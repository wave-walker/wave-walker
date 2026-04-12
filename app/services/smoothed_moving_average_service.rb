# frozen_string_literal: true

class SmoothedMovingAverageService
  def self.call(**) = new(**).call

  def initialize(ohlc:, interval:, smma_cache: nil)
    @ohlc = ohlc
    @interval = interval
    @smma_cache = smma_cache
  end

  def call
    return unless value

    smma_cache&.[]=(cache_key, value)
    { asset_pair_id: ohlc.asset_pair_id, iso8601_duration: ohlc.iso8601_duration,
      range_position: ohlc.range_position, interval:, value:, created_at: Time.current }
  end

  private

  attr_reader :ohlc, :interval, :smma_cache

  def cache_key = [ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position, interval]

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
    @last_smma ||= smma_cache&.[](last_smma_cache_key) ||
                   SmoothedMovingAverage.by_duration(ohlc.duration).find_by(
                     asset_pair_id: ohlc.asset_pair_id,
                     range_position: ohlc.range_position - 1,
                     interval:
                   )&.value
  end

  def last_smma_cache_key = [ohlc.asset_pair_id, ohlc.iso8601_duration, ohlc.range_position - 1, interval]

  def last_hl2s
    @last_hl2s ||= ohlc.previous_ohlcs.first(interval).map(&:hl2)
  end
end
