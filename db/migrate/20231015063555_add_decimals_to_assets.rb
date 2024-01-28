# frozen_string_literal: true

class AddDecimalsToAssets < ActiveRecord::Migration[7.1]
  def change
    add_column :assets, :decimals, :integer, null: false # rubocop:todo Rails/NotNullColumn
  end
end
