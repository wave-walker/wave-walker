class CreateQueSchema < ActiveRecord::Migration[7.1]
  def up
    Que.migrate!(version: 7)
  end

  def down
    Que.migrate!(version: 0)
  end
end
