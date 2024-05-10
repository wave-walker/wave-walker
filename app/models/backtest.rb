# frozen_string_literal: true

class Backtest < ApplicationRecord
  include DurationConcern

  BACKTEST_FUND = 10_000

  belongs_to :asset_pair

  has_many :smoothed_trends, query_constraints: %i[asset_pair_id iso8601_duration],
                             dependent: nil

  before_save { self.usd_quantity = BACKTEST_FUND }

  def new_smoothed_trends = smoothed_trends.where(range_position: next_range_position..)

  private

  def next_range_position = last_range_position + 1
end