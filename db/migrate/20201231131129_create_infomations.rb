class CreateInfomations < ActiveRecord::Migration[6.0]
  def change
    create_table :infomations do |t|
      t.string :title, null: false
      t.text :body
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.integer :target, null: false
      t.references :target_user, type: :bigint

      t.timestamps
    end
    add_index :infomations, [:started_at, :ended_at],  name: 'index_infomations1'
    add_index :infomations, [:target, :target_user_id], name: 'index_infomations2'
  end
end
