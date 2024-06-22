# frozen_string_literal: true

require 'application_system_test_case'

class AssetPairBacktestTest < ApplicationSystemTestCase
  setup do
    asset_pair = asset_pairs(:atomusd)

    Ohlc.where(asset_pair:).by_duration(1.day).order(:range_position)
        .each { |ohlc| SmoothedTrendService.call(ohlc) }

    BacktestJob.perform_now(backtests(:atom))

    visit(root_path)
    click_on('Asset Pairs')
  end

  def test_visualize_backtest_tades
    click_on('ATOMUSD')

    sleep 0.1 # Wait for page to load

    scroll_to(find('footer'))

    assert_text('2023-03-08 00:00:00 9,913.950796 $10.73 $202.33 $106,152.22')
    assert_text('2023-01-07 00:00:00 942.999346 $10.39 $200.00 $9,600.00')
  end
end
