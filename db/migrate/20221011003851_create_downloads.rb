class CreateDownloads < ActiveRecord::Migration[6.1]
  def change
    create_table :downloads, comment: 'ダウンロード' do |t|
      t.references :user,         null: false, type: :bigint, foreign_key: true, comment: 'ユーザーID'
      t.integer    :status,       null: false, default: 0, comment: 'ステータス'
      t.datetime   :requested_at, null: false, comment: '依頼日時'
      t.datetime   :completed_at,              comment: '完了日時'
      t.string     :error_message,             comment: 'エラーメッセージ'
      t.datetime   :last_downloaded_at,        comment: '最終ダウンロード日時'

      t.integer    :model, null: false, comment: 'モデル'
      t.references :space, type: :bigint, foreign_key: false, comment: 'スペースID'

      t.integer :target , null: false, comment: '対象'
      t.integer :format , null: false, comment: '形式'
      t.integer :char   , null: false, comment: '文字コード'
      t.integer :newline, null: false, comment: '改行コード'
      t.text :output_items,  comment: '出力項目'
      t.text :select_items,  comment: '選択項目'
      t.text :search_params, comment: '検索パラメータ'

      t.timestamps
    end
  end
end
