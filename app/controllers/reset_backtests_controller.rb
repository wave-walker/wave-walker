# frozen_string_literal: true

class ResetBacktestsController < ApplicationController
  def create
    ResetBacktestsJob.perform_later

    redirect_to backtests_path, note: 'All current backtests will be deleted later ...'
  end
end
