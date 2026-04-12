# frozen_string_literal: true

class Ohlc < ApplicationRecord
  include DurationConcern
  include RangeConcern

  belongs_to :asset_pair

has_one :smoothed_trend, foreign_key: %i[asset_pair_id iso8601_duration range_position],
                           dependent: :restrict_with_exception,
                           inverse_of: :ohlc
  has_many :smoothed_moving_averages, foreign_key: %i[asset_pair_id iso8601_duration range_position],
                                       dependent: :restrict_with_exception
  has_one :backtest_trade, foreign_key: %i[asset_pair_id iso8601_duration range_position],
                           dependent: :restrict_with_exception,
                           inverse_of: :ohlc

  scope :with_complete_smmas, lambda { |intervals|
    joins(:smoothed_moving_averages)
      .where(smoothed_moving_averages: { interval: intervals })
      .group('ohlcs.asset_pair_id, ohlcs.iso8601_duration, ohlcs.range_position')
      .having('COUNT(DISTINCT smoothed_moving_averages.interval) = ?', intervals.size)
  }

  scope :without_smoothed_trend, lambda {
    left_outer_joins(:smoothed_trend).where(smoothed_trends: { asset_pair_id: nil })
  }

  def hl2 = (high + low) / 2

  def previous_ohlcs
    self.class.where(range_position: ...range_position, asset_pair:, iso8601_duration:)
        .order(range_position: :desc)
  end
end
