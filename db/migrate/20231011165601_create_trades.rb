class CreateTrades < ActiveRecord::Migration[7.1]
  def change
    create_table :trades do |t|
      t.float :price, null: false
      t.float :volume, null: false

      t.timestamp :created_at, null: false
    end
  end
end
