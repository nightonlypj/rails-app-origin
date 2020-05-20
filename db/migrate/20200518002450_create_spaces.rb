class CreateSpaces < ActiveRecord::Migration[6.0]
  def change
    create_table :spaces do |t|
      t.string :subdomain, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :spaces, :subdomain, unique: true
  end
end
