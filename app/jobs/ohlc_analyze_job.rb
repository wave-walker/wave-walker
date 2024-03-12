# frozen_string_literal: true

class OhlcAnalyzeJob < ApplicationJob
  queue_as :default

  def perform(ohlc)
    SmoothedTrendService.call(ohlc:)
  end
end
