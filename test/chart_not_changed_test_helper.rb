# frozen_string_literal: true

module ChartNotChangedTestHelper
  class CompareChartCanvas
    def initialize(page:, element:, path:)
      @page = page
      @element = element
      @path = path
    end

    def calculate_similarity
      diff_hist = (reference.hist_find.hist_norm - capture.hist_find.hist_norm)**2

      diff_hist.avg * diff_hist.width * diff_hist.height
    end

    private

    attr_reader :page, :element, :path

    def generate_reference
      return if File.exist?(path)

      capture.write_to_file(path.to_s)
    end

    def reference
      @reference ||= begin
        generate_reference

        Vips::Image.new_from_file(path.to_s, access: :sequential)
                   .extract_band(0, n: 3)
      end
    end

    def canvas_xpath = element.find_all('canvas')[0].path

    def canvas_data_url
      page.execute_script(<<~JS)
        return document.evaluate(
          '#{canvas_xpath}',
          document,
          null,
          XPathResult.FIRST_ORDERED_NODE_TYPE,
          null
        ).singleNodeValue
         .toDataURL()
      JS
    end

    def capture
      @capture ||= begin
        image_data = Base64.decode64(canvas_data_url.sub('data:image/png;base64,', ''))

        Vips::Image.new_from_buffer(image_data, '')
                   .extract_band(0, n: 3)
      end
    end
  end

  def assert_chart_not_changed(element, capture_name:)
    caller = caller_locations(1, 1)[0].label.to_s
    path = Rails.root.join('test', 'screen_captures', self.class.name.underscore, "#{capture_name}-#{caller}.png")

    similarty = CompareChartCanvas.new(page:, element:, path:).calculate_similarity

    assert_in_delta similarty, 0, 1, 'The chart appearance has change!'
  end
end
