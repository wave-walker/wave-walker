# frozen_string_literal: true

class CreateKrakenAssetPairsJob < ApplicationJob
  queue_as :low

  def perform
    Kraken.asset_pairs.each do |params|
      name_on_exchange = params['altname']

      next unless name_on_exchange.match?(/XBT|USD/)

      name = name_on_exchange.gsub('XBT', 'BTC')

      asset_pair = AssetPair.find_or_initialize_by(name_on_exchange:)
      asset_pair.update!(name:, **params.slice('base', 'quote', 'cost_decimals'))
    end
  end
end
