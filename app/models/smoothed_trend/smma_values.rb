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
      smma_hash = smmas.index_by(&:interval)

      new(
        fast: smma_hash[SmoothedTrend::SMMA_FAST_INTERVAL]&.value,
        medium_fast: smma_hash[SmoothedTrend::SMMA_MEDIUM_FAST_INTERVAL]&.value,
        medium_slow: smma_hash[SmoothedTrend::SMMA_MEDIUM_SLOW_INTERVAL]&.value,
        slow: smma_hash[SmoothedTrend::SMMA_SLOW_INTERVAL]&.value
      )
    end

    def complete?
      @fast && @medium_fast && @medium_slow && @slow
    end
  end
end
