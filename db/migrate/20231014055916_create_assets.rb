# frozen_string_literal: true

class CreateAssets < ActiveRecord::Migration[7.1]
  def change
    create_table :assets do |t|
      t.string :name, null: false, index: { unique: true }

      t.timestamps
    end

    add_reference :trades, :asset, null: false, foreign_key: true # rubocop:todo Rails/NotNullColumn
  end
end
