# frozen_string_literal: true

module AssetPairs
  class ImportsController < ApplicationController
    def create
      asset_pair = AssetPair.find(params[:asset_pair_id])
      asset_pair.import

      redirect_to asset_pairs_path
    end
  end
end
