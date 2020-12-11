class CreateCustomers < ActiveRecord::Migration[6.0]
  def change
    create_table :customers do |t|
      t.string :name

      t.timestamps
    end
    add_index :customers, :name, unique: true, name: 'index_customers1'
  end
end
