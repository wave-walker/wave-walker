# frozen_string_literal: true

class CreateKrakenAssetPairsJob < ApplicationJob
  queue_as :default

  def perform
    Kraken.asset_pairs.each do |params|
      name_on_exchange = params['altname']

      next unless name_on_exchange.match?(/XBT|USD/)

      name = name_on_exchange.gsub('XBT', 'BTC')

      asset_pair = AssetPair.find_or_initialize_by(name_on_exchange:)
      asset_pair.name = name
      asset_pair.base = params['base']
      asset_pair.quote = params['quote']
      asset_pair.save!
    end
  end
end
