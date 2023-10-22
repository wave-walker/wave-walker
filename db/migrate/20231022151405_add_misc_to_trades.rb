class AddMiscToTrades < ActiveRecord::Migration[7.1]
  def change
    add_column :trades, :misc, :string, null: false
  end
end
