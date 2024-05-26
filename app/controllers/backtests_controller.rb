# frozen_string_literal: true

class BacktestsController < ApplicationController
  def index
    @backtests = Backtest.joins(:asset_pair)
                         .merge(AssetPair.importing)
                         .order(current_value: :desc)
  end
end
