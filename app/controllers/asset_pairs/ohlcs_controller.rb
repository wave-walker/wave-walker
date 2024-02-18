# frozen_string_literal: true

module AssetPairs
  class OhlcsController < ApplicationController
    def index
      timeframe = params[:timeframe] || 'P1D'
      asset_pair = AssetPair.find(params[:asset_pair_id])

      @ohlc_chart = OhlcChart.new(asset_pair:, timeframe:)
    end
  end
end
