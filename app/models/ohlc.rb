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

  has_many :smoothed_moving_avrages, dependent: :destroy
  has_one :smoothed_trend, dependent: :destroy

  def hl2 = (high + low) / 2

  def previous_ohlcs
    self.class.where(id: ...id, asset_pair:, duration:).order(id: :desc)
  end

  def range
    @range ||= OhlcRangeValue.at(duration:, time: start_at)
  end
end
