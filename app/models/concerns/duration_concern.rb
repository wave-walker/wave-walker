# frozen_string_literal: true

module DurationConcern
  extend ActiveSupport::Concern

  included do
    enum iso8601_duration: {
      PT1H: 'PT1H',
      PT4H: 'PT4H',
      PT8H: 'PT8H',
      P1D: 'P1D',
      P2D: 'P2D',
      P1W: 'P1W'
    }, _prefix: true

    scope :by_duration, ->(duration) { where(iso8601_duration: duration.iso8601) }
  end

  class_methods do
    def durations
      iso8601_durations.keys.map { |key| ActiveSupport::Duration.parse(key) }
    end
  end

  def duration = ActiveSupport::Duration.parse(iso8601_duration)

  def duration=(duration)
    self.iso8601_duration = duration.iso8601
  end
end
