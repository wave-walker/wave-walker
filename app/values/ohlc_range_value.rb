# frozen_string_literal: true

class OhlcRangeValue < Range
  attr_reader :duration, :position

  def initialize(position:, duration:)
    @position = position
    @duration = duration
    seconds = position * duration.seconds

    super(Time.zone.at(seconds), Time.zone.at(seconds + duration.seconds), true)
  end

  def self.at(time:, duration:)
    position = time.to_i / duration.seconds

    new(position:, duration:)
  end

  def start_at = first
  def end_at = last
  def next = self.class.new(position: position + 1, duration:)
end
