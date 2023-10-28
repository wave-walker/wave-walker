class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.order(importing: :desc, name: :asc)
  end
end
