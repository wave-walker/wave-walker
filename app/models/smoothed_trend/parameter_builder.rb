class SmoothedTrend::ParameterBuilder
  def initalize(fast_value:, slow_value:, medium_fast_value:, medium_slow_value:, last_trend:)
    @fast_value = fast_value
    @medium_fast_value = medium_fast_value
    @medium_slow_value = medium_slow_value
    @slow_value = slow_value
    @last_trend = last_trend
  end

  def call
  end

  private

  attr_reader :fast_value, :slow_value, :medium_fast_value, :medium_slow_value, :last_trend


end
