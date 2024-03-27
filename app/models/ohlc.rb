# frozen_string_literal: true

class Ohlc < ApplicationRecord
  enum timeframe: {
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
    self.class.where(id: ...id, asset_pair:, timeframe:).order(id: :desc)
  end

  def range
    @range ||= Range.new(timeframe, start_at)
  end
end
