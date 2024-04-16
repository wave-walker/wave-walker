# frozen_string_literal: true

require 'application_system_test_case'

class AssetPairChartComponentSystemTest < ApplicationSystemTestCase
  def test_asset_pair_chart
    asset_pair = asset_pairs(:atomusd)
    visit("/rails/view_components/asset_pair_chart_component/asset_pair_chart?asset_pair_id=#{asset_pair.id}")

    chart = find("#asset_pair_chard_#{asset_pair.id}").find('.tv-lightweight-charts')

    assert_element_is_unchanged(chart)
  end

  def assert_element_is_unchanged(element) # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
    caller = caller_locations(1, 1)[0].label

    path = Rails.root.join('test', 'screen_captures', self.class.name.underscore, "#{caller}.png")

    create_screenshot(path:, element:) unless File.exist?(path) || ENV['OVERRIDE_SCREEN_CAPTURE']

    reference = Vips::Image.new_from_file(path.to_s, access: :sequential)

    tempfile = Tempfile.new([caller, '.png'])
    create_screenshot(path: tempfile.path, element:)

    capture = Vips::Image.new_from_file(tempfile.path.to_s, access: :sequential)

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
