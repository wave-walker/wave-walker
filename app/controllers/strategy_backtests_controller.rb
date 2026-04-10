# frozen_string_literal: true

class StrategyBacktestsController < ApplicationController
  def index
    @strategy_backtests = StrategyBacktest.joins(:asset_pair, :strategy)
                                          .includes(:asset_pair, :strategy)
                                          .merge(AssetPair.importing)
                                          .order(current_value: :desc)
  end

  def show
    @strategy_backtest = StrategyBacktest.includes(:strategy_backtest_trades)
                                         .find(params.extract_value(:id))
  end
end
