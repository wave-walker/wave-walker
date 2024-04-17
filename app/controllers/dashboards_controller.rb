# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @recently_fliped_smooth_trends = SmoothedTrend.recent_daily_flips
  end
end
