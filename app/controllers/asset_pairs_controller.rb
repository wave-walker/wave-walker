# frozen_string_literal: true

class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.order(Arel.sql("import_status = 'importing' DESC"))
                            .order(import_status: :desc).order(:name)
  end

  def show
    @asset_pair = AssetPair.find(params[:id])
    @timeframe = params[:timeframe] || 'P1D'
  end
end