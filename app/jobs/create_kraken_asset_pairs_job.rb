# frozen_string_literal: true

class CreateKrakenAssetPairsJob < ApplicationJob
  queue_as :default

  def perform
    Kraken.asset_pairs.each do |name_on_exchange|
      next unless name_on_exchange.match?(/XBT|USD/)

      name = name_on_exchange.gsub('XBT', 'BTC')

      AssetPair.find_or_initialize_by(name_on_exchange:) do |asset_pair|
        asset_pair.name = name
        asset_pair.save!
      end
    end
  end
end
