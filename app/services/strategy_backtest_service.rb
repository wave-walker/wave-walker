# frozen_string_literal: true

class StrategyBacktestService
  def self.call(**) = new(**).call

  def initialize(strategy_backtest:, smoothed_trends:)
    @strategy_backtest = strategy_backtest
    @smoothed_trends   = smoothed_trends
    @smma_cache        = {}
  end

  def call
    return if smoothed_trends.empty?

    preload_smma_cache

    ActiveRecord::Base.transaction do
      trades = build_trades
      StrategyBacktestTrade.insert_all!(trades) unless trades.empty? # rubocop:disable Rails/SkipsModelValidations
      strategy_backtest.update!(last_range_position:, current_value:)
    end
  end

  private

  attr_reader :strategy_backtest, :smoothed_trends, :smma_cache

  def strategy         = strategy_backtest.strategy
  def asset_pair_id    = strategy_backtest.asset_pair_id
  def iso8601_duration = strategy_backtest.iso8601_duration
  def last_range_position = smoothed_trends.last.range_position
  def last_price       = smoothed_trends.last.ohlc.close
  def current_value    = strategy_backtest.usd_volume + (strategy_backtest.token_volume * last_price)

  # --- Signal resolution ---

  # Re-evaluate signal using this strategy's fast/slow SMMA intervals.
  # Falls back to nil (skip) if the required SMMA rows are missing.
  # Uses :neutral from the stored SmoothedTrend when the SMMA-derived
  # direction is bullish but the stored trend says neutral (the medium-band
  # dampener logic that produced the stored trend is preserved as-is).
  def signal_for(smoothed_trend)
    fast = smma_value(smoothed_trend, strategy.fast_interval)
    slow = smma_value(smoothed_trend, strategy.slow_interval)
    return nil if fast.nil? || slow.nil?

    # If the stored trend is neutral, honour that — neutral represents a
    # mid-band dampener regardless of which fast/slow pair the strategy uses.
    return :neutral if smoothed_trend.neutral?

    fast > slow ? :bullish : :bearish
  end

  def smma_value(smoothed_trend, interval)
    smma_cache[[smoothed_trend.range_position, interval.to_s]]
  end

  def preload_smma_cache
    range_positions = smoothed_trends.map(&:range_position)
    intervals       = [strategy.fast_interval.to_s, strategy.slow_interval.to_s]

    SmoothedMovingAverage
      .where(
        asset_pair_id:,
        iso8601_duration:,
        range_position: range_positions,
        interval: intervals
      )
      .find_each { |smma| smma_cache[[smma.range_position, smma.interval]] = smma.value }
  end

  # --- Entry / exit decision ---

  def should_trade?(smoothed_trend, signal)
    return false unless smoothed_trend.flip?

    case signal
    when :bullish
      strategy_backtest.usd_volume.positive?
    when :bearish
      strategy_backtest.token_volume.positive?
    when :neutral
      neutral_should_trade?
    else
      false
    end
  end

  def neutral_should_trade?
    (strategy.exit_neutral_or_bearish? && strategy_backtest.token_volume.positive?) ||
      (strategy.entry_bullish_or_neutral? && strategy_backtest.usd_volume.positive?)
  end

  # --- Trade building ---

  def action_for(signal, _smoothed_trend)
    case signal
    when :bullish
      :buy
    when :bearish
      :sell
    when :neutral
      # Neutral can mean exit (exit_neutral_or_bearish) or entry (entry_bullish_or_neutral).
      # Exit takes priority when tokens are held.
      if strategy.exit_neutral_or_bearish? && strategy_backtest.token_volume.positive?
        :sell
      else
        :buy
      end
    end
  end

  def build_trade(smoothed_trend, signal)
    action = action_for(signal, smoothed_trend)
    ohlc   = smoothed_trend.ohlc

    StrategyTradeBuilder.build(
      ohlc:,
      strategy_backtest:,
      action:,
      slippage: strategy.slippage,
      fee_rate: strategy.fee
    ).tap do |trade_params|
      price, volume = trade_params.values_at(:price, :volume)

      if action == :buy
        strategy_backtest.usd_volume   = 0
        strategy_backtest.token_volume = volume
      else
        strategy_backtest.token_volume = 0
        strategy_backtest.usd_volume   = volume * price
      end
    end
  end

  # Order-dependent: each call to build_trade mutates strategy_backtest.usd_volume /
  # token_volume so that subsequent iterations see the updated portfolio state.
  # smoothed_trends must be ordered by range_position ascending.
  def build_trades
    smoothed_trends.filter_map do |smoothed_trend|
      signal = signal_for(smoothed_trend)
      next unless signal && should_trade?(smoothed_trend, signal)

      build_trade(smoothed_trend, signal)
    end
  end
end
