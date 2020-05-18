class CreateSpaces < ActiveRecord::Migration[6.0]
  def change
    create_table :spaces do |t|
      t.string :subdomain
      t.string :name

      t.timestamps
    end
  end
end
