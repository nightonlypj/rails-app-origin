class CreateSpaces < ActiveRecord::Migration[6.0]
  def change
    create_table :spaces do |t|
      t.references :customer, null: false, foreign_key: true, type: :bigint

      t.string :subdomain, null: false
      t.string :image # json: PostgreSQL/MySQL, string: SQLite/MariaDB(MySQLでもOK)
      t.string :name, null: false

      t.string :purpose
      t.boolean :public_flag, null: false, default: false
      t.integer :sort_key, null: false, default: 0

      t.timestamps
    end
    add_index :spaces, :subdomain, unique: true, name: 'index_spaces1'
    add_index :spaces, [:created_at, :id],       name: 'index_spaces2'
  end
end
