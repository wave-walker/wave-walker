# frozen_string_literal: true

class AssetPairImportsController < ApplicationController
  def new
    @asset_pairs = AssetPair.pending.order(:name)
  end

  def create
    asset_pair = AssetPair.find(params[:asset_pair_id])
    asset_pair.import

    redirect_to asset_pairs_path, notice: "Importing #{asset_pair.name}"
  end

  def destroy
    asset_pair = AssetPair.find(params[:asset_pair_id])
    asset_pair.disable_import

    redirect_to asset_pairs_path, notice: "Importing disabled for #{asset_pair.name}"
  end
end
