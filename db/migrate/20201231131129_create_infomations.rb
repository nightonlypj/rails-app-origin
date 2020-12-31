class CreateInfomations < ActiveRecord::Migration[6.0]
  def change
    create_table :infomations do |t|
      t.string :title
      t.text :body
      t.integer :target
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
