class CreateCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :customer_users do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :power

      t.timestamps
    end
  end
end
