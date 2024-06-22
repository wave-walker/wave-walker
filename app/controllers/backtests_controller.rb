# frozen_string_literal: true

class BacktestsController < ApplicationController
  def index
    @backtests = Backtest.joins(:asset_pair)
                         .merge(AssetPair.importing)
                         .order(current_value: :desc)
  end

  def show
    @backtest = Backtest.includes(:backtest_trades).find(params.extract_value(:id))
  end
end
