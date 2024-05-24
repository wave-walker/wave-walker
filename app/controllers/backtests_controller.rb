# frozen_string_literal: true

class BacktestsController < ApplicationController
  def index
    @backtests = Backtest.order(current_value: :desc)
  end
end
