# frozen_string_literal: true

class AssetPairSyncJob < ApplicationJob
  queue_as :default

  def perform
    AssetPair.importing.find_each do |asset_pair|
      TradeImportJob.perform_later(asset_pair)
    end
  end
end
