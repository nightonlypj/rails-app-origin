# frozen_string_literal: true

class DeviseTokenAuthChangeUsers < ActiveRecord::Migration[6.1]
  def change
    ## Required
    add_column :users, :provider, :string, null: false, default: 'email', comment: '認証方法'
    add_column :users, :uid,      :string, null: false, default: '',      comment: 'UID'
    ActiveRecord::Base.connection.execute('UPDATE users SET uid = email')

    ## Recoverable
    add_column :users, :allow_password_change, :boolean, default: false, comment: 'パスワード再設定中'

    ## User Info
    # add_column :users, :nickname, :string, comment: 'ニックネーム' # NOTE: 未使用

    ## Tokens
    add_column :users, :tokens, :text, comment: '認証トークン'

    add_index :users, %i[uid provider], unique: true, name: 'index_users7'
  end
end
