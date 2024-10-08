# frozen_string_literal: true

class AddOrderTypeToTrades < ActiveRecord::Migration[7.1]
  def up
    execute "CREATE TYPE order_type AS ENUM ('market', 'limit')"
    add_column :trades, :order_type, :order_type, null: false # rubocop:todo Rails/NotNullColumn
  end

  def down
    remove_column :trades, :order_type
    execute 'DROP TYPE order_type'
  end
end
