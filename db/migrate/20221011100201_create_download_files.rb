class CreateDownloadFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :download_files do |t|
      t.references :download, null: false, foreign_key: true

      t.timestamps
    end
  end
end
