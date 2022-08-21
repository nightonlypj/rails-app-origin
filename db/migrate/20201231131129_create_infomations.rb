class CreateInfomations < ActiveRecord::Migration[6.0]
  def change
    create_table :infomations, comment: 'お知らせ' do |t|
      t.string :title, null: false, comment: 'タイトル'
      t.string :summary,            comment: '概要'
      t.text   :body,               comment: '本文'

      t.datetime :started_at, null: false, comment: '開始日時'
      t.datetime :ended_at,                comment: '終了日時'

      t.integer    :target, null: false, comment: '対象'
      t.references :user, type: :bigint, foreign_key: true, comment: 'ユーザーID'

      t.timestamps
    end
    add_index :infomations, [:started_at, :id],       name: 'index_infomations1'
    add_index :infomations, [:started_at, :ended_at], name: 'index_infomations2'
    add_index :infomations, [:target, :user_id],      name: 'index_infomations3'
  end
end
