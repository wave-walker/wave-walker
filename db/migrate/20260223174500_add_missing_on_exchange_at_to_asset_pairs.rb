class AddMissingOnExchangeAtToAssetPairs < ActiveRecord::Migration[8.0]
  def change
    add_column :asset_pairs, :missing_on_exchange_at, :datetime
    add_index :asset_pairs, :missing_on_exchange_at
  end
end
