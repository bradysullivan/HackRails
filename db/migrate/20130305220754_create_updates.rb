class CreateUpdates < ActiveRecord::Migration
  def change
    create_table :updates do |t|
      t.string :before
      t.string :after
      t.string :commits
      t.string :ref

      t.timestamps
    end
  end
end
