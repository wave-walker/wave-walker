# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Strategy matrix: 27 combinations of SMMA intervals, entry/exit rules, and cost assumptions.
#
# To add a new strategy simply add a new find_or_create_by! block below and run bin/rails db:seed.

interval_pairs = [
  { fast_interval: 10, slow_interval: 28 },
  { fast_interval: 12, slow_interval: 26 },
  { fast_interval: 16, slow_interval: 28 }
]

signal_combos = [
  { entry_on: 'bullish',            exit_on: 'neutral_or_bearish' },
  { entry_on: 'bullish',            exit_on: 'bearish_only'       },
  { entry_on: 'bullish_or_neutral', exit_on: 'neutral_or_bearish' }
]

cost_configs = [
  { slippage: 0.005, fee: 0.005, cost_label: '0.5%' },
  { slippage: 0.01,  fee: 0.01,  cost_label: '1%'   },
  { slippage: 0.02,  fee: 0.02,  cost_label: '2%'   }
]

interval_pairs.each do |intervals|
  signal_combos.each do |signals|
    cost_configs.each do |costs|
      name = "SMMA #{intervals[:fast_interval]}/#{intervals[:slow_interval]} | " \
             "#{signals[:entry_on]} entry | #{signals[:exit_on]} exit | #{costs[:cost_label]} fee"

      strategy = Strategy.find_or_create_by!(name:) do |s|
        s.fast_interval = intervals[:fast_interval]
        s.slow_interval = intervals[:slow_interval]
        s.entry_on      = signals[:entry_on]
        s.exit_on       = signals[:exit_on]
        s.slippage      = costs[:slippage]
        s.fee           = costs[:fee]
      end

      # AssetPair#after_create normally creates strategy_backtests for all existing
      # strategies. This block handles the inverse: when a new strategy is seeded,
      # it back-fills backtests for asset pairs that already exist.
      AssetPair.importing.find_each do |asset_pair|
        Ohlc.durations.each do |duration|
          StrategyBacktest.find_or_create_by!(
            strategy:,
            asset_pair:,
            iso8601_duration: duration.iso8601
          )
        end
      end
    end
  end
end
