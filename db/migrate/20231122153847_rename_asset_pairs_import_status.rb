# frozen_string_literal: true

class RenameAssetPairsImportStatus < ActiveRecord::Migration[7.1]
  def change
    rename_column :asset_pairs, :import_state, :import_status
  end
end
