# frozen_string_literal: true

class DeviseCreateAdminUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :admin_users, comment: '管理者' do |t|
      t.string :name, null: false, comment: '氏名'

      ## Database authenticatable
      t.string :email,              null: false, default: '', comment: 'メールアドレス'
      t.string :encrypted_password, null: false, default: '', comment: '暗号化されたパスワード'

      ## Recoverable
      t.string   :reset_password_token,   comment: 'パスワードリセットトークン'
      t.datetime :reset_password_sent_at, comment: 'パスワードリセット送信日時'

      ## Rememberable
      t.datetime :remember_created_at, comment: 'ログイン状態維持開始日時'

      ## Trackable
      t.integer  :sign_in_count, null: false, default: 0, comment: 'ログイン回数'
      t.datetime :current_sign_in_at,                     comment: '現在のログイン日時'
      t.datetime :last_sign_in_at,                        comment: '最終ログイン日時'
      t.string   :current_sign_in_ip,                     comment: '現在のログインIPアドレス'
      t.string   :last_sign_in_ip,                        comment: '最終ログインIPアドレス'

      ## Confirmable
      t.string   :confirmation_token,   comment: 'メールアドレス確認トークン'
      t.datetime :confirmed_at,         comment: 'メールアドレス確認日時'
      t.datetime :confirmation_sent_at, comment: 'メールアドレス確認送信日時'
      t.string   :unconfirmed_email,    comment: '確認待ちメールアドレス' # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, null: false, default: 0, comment: '連続ログイン失敗回数' # Only if lock strategy is :failed_attempts
      t.string   :unlock_token,                             comment: 'アカウントロック解除トークン' # Only if unlock strategy is :email or :both
      t.datetime :locked_at,                                comment: 'アカウントロック日時'

      t.timestamps
    end

    add_index :admin_users, :email,                unique: true, name: 'index_admin_users1'
    add_index :admin_users, :reset_password_token, unique: true, name: 'index_admin_users2'
    add_index :admin_users, :confirmation_token,   unique: true, name: 'index_admin_users3'
    add_index :admin_users, :unlock_token,         unique: true, name: 'index_admin_users4'
  end
end
