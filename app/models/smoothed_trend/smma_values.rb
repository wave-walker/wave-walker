# frozen_string_literal: true

class SmoothedTrend
  class SmmaValues
    attr_reader :fast, :medium_fast, :medium_slow, :slow

    def initialize(fast:, medium_fast:, medium_slow:, slow:)
      @fast = fast
      @medium_fast = medium_fast
      @medium_slow = medium_slow
      @slow = slow
    end

    def self.from_array(smmas)
      values = { fast: nil, medium_fast: nil, medium_slow: nil, slow: nil }
      smmas.each do |smma|
        case smma.interval
        when SmoothedTrend::SMMA_FAST_INTERVAL then values[:fast] = smma.value
        when SmoothedTrend::SMMA_MEDIUM_FAST_INTERVAL then values[:medium_fast] = smma.value
        when SmoothedTrend::SMMA_MEDIUM_SLOW_INTERVAL then values[:medium_slow] = smma.value
        when SmoothedTrend::SMMA_SLOW_INTERVAL        then values[:slow] = smma.value
        end
      end

      new(**values)
    end

    def complete?
      [fast, medium_fast, medium_slow, slow].all? { |v| !v.nil? }
    end
  end
end
