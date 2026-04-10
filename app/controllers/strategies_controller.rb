# frozen_string_literal: true

class StrategiesController < ApplicationController
  def index
    @strategies = Strategy.order(:name)
  end

  def show
    @strategy = Strategy.find(params[:id])
    @strategy_backtests = @strategy.strategy_backtests
                                   .joins(:asset_pair)
                                   .order(current_value: :desc)
  end
end
