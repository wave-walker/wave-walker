# frozen_string_literal: true

class ResetStrategyBacktestsController < ApplicationController
  def create
    ResetStrategyBacktestsJob.perform_later

    redirect_to strategy_backtests_path, notice: 'All strategy backtests will be reset shortly...'
  end
end
