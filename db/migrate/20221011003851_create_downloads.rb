class CreateDownloads < ActiveRecord::Migration[6.1]
  def change
    create_table :downloads do |t|

      t.timestamps
    end
  end
end
