# frozen_string_literal: true

module ApplicationHelper
  def flash_class(level)
    case level
    when 'notice'
      'flash__info'
    when 'alert'
      'flash__danger'
    else
      raise "Unknown flash level: #{level}"
    end
  end

  def duration_to_timeframe(duration)
    {
      'PT1H' => '1H',
      'PT4H' => '4H',
      'PT8H' => '8H',
      'P1D' => '1D',
      'P2D' => '2D',
      'P1W' => '1W'
    }.fetch(duration.iso8601)
  end
end
