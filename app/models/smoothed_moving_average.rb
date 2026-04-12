# frozen_string_literal: true

class SmoothedMovingAverage < ApplicationRecord
  include DurationConcern

  INTERVALS = [16, 28, 19, 25].freeze
end
