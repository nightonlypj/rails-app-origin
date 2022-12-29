class CreateSpaces < ActiveRecord::Migration[6.1]
  def change
    create_table :spaces, comment: 'スペース' do |t|
      t.string :code, null: false, comment: 'コード'
      t.string :image,             comment: '画像' # json: PostgreSQL/MySQL, string: SQLite/MariaDB(MySQLでもOK)
      t.string :name, null: false, comment: '名称'
      t.text   :description,       comment: '説明'

      t.boolean :private, null: false, default: true, comment: '非公開'

      t.datetime :destroy_requested_at, comment: '削除依頼日時'
      t.datetime :destroy_schedule_at,  comment: '削除予定日時'

      t.references :created_user, null: false, type: :bigint, foreign_key: false, comment: '作成者ID'
      t.references :last_updated_user,         type: :bigint, foreign_key: false, comment: '最終更新者ID'
      t.timestamps
    end
    add_index :spaces, :code, unique: true,  name: 'index_spaces1'
    add_index :spaces, :destroy_schedule_at, name: 'index_spaces2'
    add_index :spaces, [:created_at, :id],   name: 'index_spaces3'
    add_index :spaces, [:name, :id],         name: 'index_spaces4'
  end
end
