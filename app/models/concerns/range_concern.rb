# frozen_string_literal: true

module RangeConcern
  extend ActiveSupport::Concern

  def range
    @range ||= OhlcRangeValue.new(duration:, position: range_position)
  end
end
