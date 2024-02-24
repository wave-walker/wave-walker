# frozen_string_literal: true

class AssetPairSyncJob < ApplicationJob
  queue_as :default

  def perform
    AssetPair.imported.order(id: :desc).find_each(&:start_import)
  end
end
