# frozen_string_literal: true

module AssetPairs
  class ChartsController < ApplicationController
    def show
      @asset_pair = AssetPair.find(params.expect(:asset_pair_id))
      @duration = params[:id]
    end
  end
end
