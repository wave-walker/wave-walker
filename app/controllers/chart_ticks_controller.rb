# frozen_string_literal: true

class ChartTicksController < ApplicationController
  def index
    @ohlcs = Ohlc.by_duration(duration)
                 .includes(:smoothed_trend)
                 .where(asset_pair:)
                 .last(300)
  end

  private

  def duration = ActiveSupport::Duration.parse(params.fetch(:duration_id))
  def asset_pair = AssetPair.find(params.fetch(:asset_pair_id))
end
