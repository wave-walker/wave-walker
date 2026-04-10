# frozen_string_literal: true

class StrategyBacktest < ApplicationRecord
  include DurationConcern

  self.primary_key = %i[strategy_id asset_pair_id iso8601_duration]

  belongs_to :strategy
  belongs_to :asset_pair

  has_many :strategy_backtest_trades, -> { order(range_position: :desc) },
           foreign_key: %i[strategy_id asset_pair_id iso8601_duration],
           dependent: :destroy,
           inverse_of: :strategy_backtest

  has_many :smoothed_trends, ->(sb) { where(iso8601_duration: sb.iso8601_duration) },
           foreign_key: :asset_pair_id,
           primary_key: :asset_pair_id,
           dependent: nil, inverse_of: false

  before_create do
    self.usd_volume    = Backtest::BACKTEST_FUND
    self.current_value = Backtest::BACKTEST_FUND
  end

  def new_smoothed_trends = smoothed_trends.where(range_position: next_range_position..)
  def percentage_change = (current_value - Backtest::BACKTEST_FUND) / Backtest::BACKTEST_FUND * 100

  private

  def next_range_position = last_range_position + 1
end
