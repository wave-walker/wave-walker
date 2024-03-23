# frozen_string_literal: true

class SmoothedMovingAverageService
  def self.call(**) = new(**).call

  def initialize(ohlc:, interval:)
    @ohlc = ohlc
    @interval = interval
  end

  def call
    return unless value

    SmoothedMovingAverage.create!(id: [ohlc.id, interval], value:)
  end

  private

  attr_reader :ohlc, :interval

  def value = smma || sma

  def smma
    return unless last_smma

    ((last_smma * (interval - 1)) + ohlc.hl2) / interval
  end

  def sma
    return if last_hl2s.count != interval

    last_hl2s.sum / interval
  end

  def last_ohlc = ohlc.previous_ohlcs.first

  def last_smma
    @last_smma ||= SmoothedMovingAverage.find_by(ohlc: last_ohlc, interval:)&.value
  end

  def last_hl2s
    @last_hl2s ||= ohlc.previous_ohlcs.first(interval).map(&:hl2)
  end
end
