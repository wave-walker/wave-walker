# frozen_string_literal: true

class Ohlc < ApplicationRecord
  enum duration: {
    PT1H: 'PT1H',
    PT4H: 'PT4H',
    PT8H: 'PT8H',
    P1D: 'P1D',
    P2D: 'P2D',
    P1W: 'P1W'
  }, _prefix: true

  belongs_to :asset_pair

  has_one :smoothed_trend, query_constraints: %i[asset_pair_id duration range_position],
                           dependent: :restrict_with_exception

  def hl2 = (high + low) / 2

  def previous_ohlcs
    self.class.where(range_position: ...range_position, asset_pair:, duration:)
        .order(range_position: :desc)
  end

  def range
    @range ||= OhlcRangeValue.new(duration:, position: range_position)
  end
end
