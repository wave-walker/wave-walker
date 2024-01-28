# frozen_string_literal: true

class AssetSyncService
  def self.call
    new.call
  end

  def call
    assets = Kraken.assets

    assets.each do |name, data|
      asset = Asset.find_or_initialize_by(name:)
      asset.decimals = data.fetch('decimals')
      asset.save!
    end
  end
end
