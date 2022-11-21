class CreateDownloadFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :download_files, comment: 'ダウンロードファイル' do |t|
      t.references :download, null: false, type: :bigint, foreign_key: true, comment: 'ダウンロードID'
      t.binary :body, size: :long, comment: '内容'

      t.timestamps
    end
  end
end
