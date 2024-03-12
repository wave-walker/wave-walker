# frozen_string_literal: true

require 'test_helper'

class OhlcAnalyzeJobTest < ActiveJob::TestCase
  test 'creates the SmoothedTrend' do
    ohlc = create_ohlc

    SmoothedTrendService.expects(:call).with(ohlc:)

    OhlcAnalyzeJob.perform_now(ohlc)
  end

  def create_ohlc
    asset_pair = asset_pairs(:atomusd)
    timeframe = :PT1H
    range = Ohlc::Range.new(timeframe, Time.current)
    Ohlc.new(asset_pair:, high: 1, low: 2, open: 3, close: 4, volume: 1,
             timeframe:, start_at: range.begin)
  end
end
