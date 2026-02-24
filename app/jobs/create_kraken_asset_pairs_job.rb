# frozen_string_literal: true

class CreateKrakenAssetPairsJob < ApplicationJob
  queue_as :low

  USD_QUOTE = 'ZUSD'

  def perform
    usd_asset_pairs = fetch_usd_asset_pairs
    return if usd_asset_pairs.empty?

    mark_missing_usd_pairs(usd_asset_pairs)
    upsert_usd_pairs(usd_asset_pairs)
  end

  private

  def usd_pair?(params)
    params.fetch('quote') == USD_QUOTE || params.fetch('altname').end_with?('USD')
  end

  def fetch_usd_asset_pairs
    Kraken.asset_pairs.select { |params| usd_pair?(params) }
  end

  def mark_missing_usd_pairs(usd_asset_pairs)
    name_on_exchange_set = usd_asset_pairs.map { |params| params.fetch('altname') }

    AssetPair
      .usd
      .where.not(name_on_exchange: name_on_exchange_set)
      .where(missing_on_exchange_at: nil)
      .find_each do |asset_pair|
        asset_pair.update!(missing_on_exchange_at: Time.current, importing: false)
    end
  end

  def upsert_usd_pairs(usd_asset_pairs)
    usd_asset_pairs.each do |params|
      name_on_exchange = params.fetch('altname')
      name = name_on_exchange.gsub('XBT', 'BTC')

      asset_pair = AssetPair.find_or_initialize_by(name_on_exchange:)
      asset_pair.update!(
        name:,
        **params.slice('base', 'quote', 'cost_decimals'),
        missing_on_exchange_at: nil
      )
    end
  end
end
