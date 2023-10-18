class RemoveAssetsSequence < ActiveRecord::Migration[7.1]
  def up
    execute 'DROP SEQUENCE trades_id_seq CASCADE'
  end

  def down
    execute <<-SQL
      CREATE SEQUENCE trades_id_seq
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1
    SQL

    execute 'ALTER SEQUENCE trades_id_seq OWNED BY trades.id'

    execute("SELECT setval('trades_id_seq', coalesce((SELECT MAX(id)+1 FROM trades), 1), false)")
  end
end
