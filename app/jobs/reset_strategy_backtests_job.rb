# frozen_string_literal: true

class ResetStrategyBacktestsJob < ApplicationJob
  include JobIteration::Iteration

  queue_as :default

  def build_enumerator(cursor:)
    enumerator_builder.active_record_on_records(AssetPair.all, cursor:)
  end

  def each_iteration(asset_pair)
    asset_pair.reset_strategy_backtests
  end
end
