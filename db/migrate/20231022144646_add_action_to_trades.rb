# frozen_string_literal: true

class AddActionToTrades < ActiveRecord::Migration[7.1]
  def up
    execute "CREATE TYPE trade_action AS ENUM ('buy', 'sell')"
    add_column :trades, :action, :trade_action, null: false # rubocop:todo Rails/NotNullColumn
  end

  def down
    remove_column :trades, :action
    execute 'DROP TYPE trade_action'
  end
end
