class CreateInfomations < ActiveRecord::Migration[6.0]
  def change
    create_table :infomations do |t|
      t.string :title
      t.string :summary
      t.text   :body

      t.datetime :started_at, null: false
      t.datetime :ended_at

      t.integer    :target, null: false
      t.references :user, type: :bigint

      t.string     :action
      t.bigint     :action_user_id
      t.references :customer, type: :bigint
      t.references :space, type: :bigint

      t.timestamps
    end
    add_index :infomations, [:started_at, :id],       name: 'index_infomations1'
    add_index :infomations, [:started_at, :ended_at], name: 'index_infomations2'
    add_index :infomations, [:target, :user_id],      name: 'index_infomations3'
  end
end
