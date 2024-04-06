# frozen_string_literal: true

class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.importing.order(:name)
  end

  def show
    @asset_pair = AssetPair.find(params[:id])
    @duration = params[:duration] || 'P1D'
  end
end
