class CreateCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :customer_users do |t|
      t.references :customer, null: false, foreign_key: true, type: :bigint
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.integer :power, null: false

      t.timestamps
    end
    add_index :customer_users, [:customer_id, :user_id], unique: true, name: 'index_customer_users1'
  end
end
