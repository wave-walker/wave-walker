# frozen_string_literal: true

class AssetPairChartComponentPreview < ViewComponent::Preview
  def asset_pair_chart(asset_pair_id: AssetPair.first.id)
    asset_pair = AssetPair.find(asset_pair_id)
    render(AssetPairChartComponent.new(asset_pair:, duration: 1.day))
  end
end
