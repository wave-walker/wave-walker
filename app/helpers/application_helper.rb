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
end
