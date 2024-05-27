# frozen_string_literal: true

class AssetPairPresenter
  attr_reader :asset_pair, :duration

  def initialize(asset_pair:, duration:)
    @asset_pair = asset_pair
    @duration = duration
  end

  def chart_id = "asset_pair_chard_#{asset_pair.id}"
  def iso8601_duration = duration.iso8601
  delegate :name, to: :asset_pair

  def chart_price_format
    {
      type: 'price',
      precision: asset_pair.cost_decimals,
      minMove: 1.0 / (10**asset_pair.cost_decimals)
    }
  end
end
