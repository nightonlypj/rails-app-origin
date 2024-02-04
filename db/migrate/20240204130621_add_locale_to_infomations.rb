class AddLocaleToInfomations < ActiveRecord::Migration[7.0]
  def change
    add_column :infomations, :locale, :string, comment: '地域'

    add_index :infomations, :locale, name: 'index_infomations5'
  end
end
