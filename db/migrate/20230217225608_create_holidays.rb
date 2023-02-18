class CreateHolidays < ActiveRecord::Migration[6.1]
  def change
    create_table :holidays, comment: '祝日' do |t|
      t.date :date, null: false, comment: '日付'
      t.string :name, null: false, comment: '名称'

      t.timestamps
    end
    add_index :holidays, :date, unique: true, name: 'index_holidays1'
  end
end
