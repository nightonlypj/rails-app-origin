class CreateMembers < ActiveRecord::Migration[6.0]
  def change
    create_table :members do |t|
      t.references :customer, null: false, foreign_key: true, type: :bigint
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.integer :power, null: false
      t.datetime :invitationed_at

      t.timestamps
    end
    add_index :members, [:customer_id, :user_id], unique: true, name: 'index_members1'
    add_index :members, [:created_at, :id],                     name: 'index_members2'
  end
end
