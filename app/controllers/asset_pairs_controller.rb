# frozen_string_literal: true

class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.importing.order(:name)
  end

  def show
    @asset_pair = AssetPair.find(params.expect(:id))
    @duration = ActiveSupport::Duration.parse(params[:iso8601_duration] || 'P1D')
    @backtest = Backtest.find([params.expect(:id), @duration.iso8601])
  end
end
