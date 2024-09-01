# frozen_string_literal: true

require 'application_system_test_case'
require 'chart_not_changed_test_helper'

class AssetPairChartTest < ApplicationSystemTestCase
  include ChartNotChangedTestHelper

  setup do
    asset_pair = asset_pairs(:atomusd)

    Ohlc.where(asset_pair:).by_duration(1.day).order(:range_position)
        .each { |ohlc| SmoothedTrendService.call(ohlc) }

    BacktestJob.perform_now(backtests(:atom))

    visit(root_path)
    click_on('Asset Pairs')
  end

  def test_asset_pair_chart
    click_on('ATOMUSD')

    chart = find('.tv-lightweight-charts')

    assert_chart_not_changed(chart, capture_name: 'chart')
  end

  def test_asset_pair_chart_scall_and_load_more_data
    stub_const(ChartTicksController, :TICK_COUNT, 30) do
      click_on('ATOMUSD')

      chart = find('.tv-lightweight-charts')

      assert_chart_not_changed(chart, capture_name: 'before_scroll')

      # 5th canvas is registering the mouse events
      chart.all('canvas')[5].drag_to(chart)

      assert_chart_not_changed(chart, capture_name: 'after_scroll')
    end
  end
end
