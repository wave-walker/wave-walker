class CreateTrades < ActiveRecord::Migration[7.1]
  def change
    create_table :trades do |t|
      t.decimal :price, precision: 20, scale: 10, null: false
      t.decimal :volume, precision: 20, scale: 10, null: false

      t.timestamp :created_at, null: false
    end
  end
end
