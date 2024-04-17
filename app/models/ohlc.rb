# frozen_string_literal: true

class Ohlc < ApplicationRecord
  include DurationConcern
  include RangeConcern

  belongs_to :asset_pair

  has_one :smoothed_trend, query_constraints: %i[asset_pair_id iso8601_duration range_position],
                           dependent: :restrict_with_exception

  def hl2 = (high + low) / 2

  def previous_ohlcs
    self.class.where(range_position: ...range_position, asset_pair:, iso8601_duration:)
        .order(range_position: :desc)
  end
end
