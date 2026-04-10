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

  # The scoped lambda filters by iso8601_duration at the instance level.
  # Note: this scope does NOT apply when using joins/includes on this association
  # because Rails evaluates it per-instance. new_smoothed_trends relies on
  # the instance-level scope; use that method rather than the association directly.
  has_many :smoothed_trends, ->(sb) { where(iso8601_duration: sb.iso8601_duration) },
           foreign_key: :asset_pair_id,
           primary_key: :asset_pair_id,
           dependent: nil, inverse_of: false

  before_create do
    self.usd_volume    = BACKTEST_FUND
    self.current_value = BACKTEST_FUND
  end

  def new_smoothed_trends = smoothed_trends.where(range_position: next_range_position..)
  def percentage_change = (current_value - BACKTEST_FUND) / BACKTEST_FUND * 100

  private

  def next_range_position = last_range_position + 1
end
