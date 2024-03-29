# frozen_string_literal: true

class AddImportedUntilToAssetPairs < ActiveRecord::Migration[7.1]
  def change
    add_column :asset_pairs, :imported_until, :datetime
  end
end
