class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.order(name: :asc)
  end
end
