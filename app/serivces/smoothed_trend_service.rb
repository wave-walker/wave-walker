# frozen_string_literal: true

class SmoothedTrendService
  def self.call(ohlc) = new(ohlc).call

  def initialize(ohlc)
    @ohlc = ohlc
  end

  def call
    ActiveRecord::Base.transaction do
      create_smmas
      SmoothedTrend.create!(ohlc:, fast_smma:, slow_smma:, trend:) if valid?
    end
  end

  private

  attr_reader :ohlc, :fast_smma, :slow_smma, :medium_fast_smma, :medium_slow_smma

  def create_smmas
    @fast_smma = SmoothedMovingAverageService.call(ohlc:, interval: 16)&.value
    @slow_smma = SmoothedMovingAverageService.call(ohlc:, interval: 28)&.value
    @medium_fast_smma = SmoothedMovingAverageService.call(ohlc:, interval: 19)&.value
    @medium_slow_smma = SmoothedMovingAverageService.call(ohlc:, interval: 25)&.value
  end

  def valid? = fast_smma && slow_smma && medium_fast_smma && medium_slow_smma

  def trend
    return :neutral if neutral?
    return :bullish if bullish?

    :bearish
  end

  def bullish? = fast_smma > slow_smma
  def neutral_up? = (fast_smma < medium_fast_smma) == bullish?
  def neutral_down? = (medium_slow_smma < slow_smma) == bullish?
  def neutral? = neutral_up? || neutral_down?
end
