# frozen_string_literal: true

class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.importing.order(:name)
  end

  def show
    @asset_pair = AssetPair.find(params[:id])
    @timeframe = params[:timeframe] || 'P1D'
  end
end
