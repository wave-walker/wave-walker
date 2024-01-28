# frozen_string_literal: true

class AddMiscToTrades < ActiveRecord::Migration[7.1]
  def change
    add_column :trades, :misc, :string, null: false # rubocop:todo Rails/NotNullColumn
  end
end
