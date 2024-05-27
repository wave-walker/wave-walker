# frozen_string_literal: true

class AssetPairsController < ApplicationController
  def index
    @asset_pairs = AssetPair.importing.order(:name)
  end

  def show
    asset_pair = AssetPair.find(params[:id])
    duration = ActiveSupport::Duration.parse(params[:iso8601_duration] || 'P1D')

    @asset_pair_presenter = AssetPairPresenter.new(asset_pair:, duration:)
  end
end
