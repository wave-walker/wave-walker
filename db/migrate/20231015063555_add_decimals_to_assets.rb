class AddDecimalsToAssets < ActiveRecord::Migration[7.1]
  def change
    add_column :assets, :decimals, :integer, null: false
  end
end
