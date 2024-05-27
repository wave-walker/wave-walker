# frozen_string_literal: true

require 'application_system_test_case'

class AssetPairChartTest < ApplicationSystemTestCase
  setup do
    asset_pair = asset_pairs(:atomusd)

    Ohlc.where(asset_pair:).by_duration(1.day).order(:range_position)
        .each { |ohlc| SmoothedTrendService.call(ohlc) }

    visit(root_path)
    click_on('Asset Pairs')
  end

  def test_asset_pair_chart
    click_on('ATOMUSD')

    chart = find('.tv-lightweight-charts')

    assert_element_is_unchanged(chart, capture_name: 'chart')
  end

  def test_asset_pair_chart_scall_and_load_more_data
    stub_const(ChartTicksController, :TICK_COUNT, 30) do
      click_on('ATOMUSD')

      chart = find('.tv-lightweight-charts')

      assert_element_is_unchanged(chart, capture_name: 'before_scroll')

      # 5th canvas is registering the mouse events
      chart.all('canvas')[5].drag_to(chart)

      assert_element_is_unchanged(chart, capture_name: 'after_scroll')
    end
  end

  private

  def assert_element_is_unchanged(element, capture_name:) # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
    caller = caller_locations(1, 1)[0].label

    path = Rails.root.join('test', 'screen_captures', self.class.name.underscore, "#{capture_name}-#{caller}.png")

    create_screenshot(path:, element:) unless File.exist?(path) || ENV['OVERRIDE_SCREEN_CAPTURE']

    reference = Vips::Image.new_from_file(path.to_s, access: :sequential)
                           .extract_band(0, n: 3)

    tempfile = Tempfile.new([caller, '.png'])
    create_screenshot(path: tempfile.path, element:)

    capture = Vips::Image.new_from_file(tempfile.path.to_s, access: :sequential)
                         .extract_band(0, n: 3)

    diff_hist = (reference.hist_find.hist_norm - capture.hist_find.hist_norm)**2
    tempfile.unlink

    similarty = diff_hist.avg * diff_hist.width * diff_hist.height

    assert_in_delta similarty, 0, 0.5, 'The elements appearance has change'
  end

  def create_screenshot(path:, element:)
    scroll_to(element)

    Tempfile.open(['capture', '.png']) do |tempfile|
      save_screenshot(tempfile.path) # rubocop:disable Lint/Debugger

      Vips::Image.new_from_file(tempfile.path.to_s)
                 .crop(element.rect.x, 0, element.rect.width, element.rect.height)
                 .write_to_file(path.to_s, Q: 80)
    end
  end
end
