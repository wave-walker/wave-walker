# frozen_string_literal: true

class ChartTicksController < ApplicationController
  TICK_COUNT = 300

  def index
    @ohlcs = Ohlc.by_duration(duration)
                 .includes(:smoothed_trend, backtest_trade: :backtest)
                 .where(asset_pair:)

    @ohlcs = @ohlcs.where(range_position: ...params[:next_range_position]) if params[:next_range_position].present?
    @ohlcs = @ohlcs.last(TICK_COUNT)
  end

  private

  def duration = ActiveSupport::Duration.parse(params.fetch(:duration_id))
  def asset_pair = AssetPair.find(params.fetch(:asset_pair_id))
end
