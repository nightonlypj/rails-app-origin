# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :code, null: false
      t.string :image
      t.string :name, null: false

      ## Database authenticatable
      t.string :email,              null: false, default: ''
      t.string :encrypted_password, null: false, default: ''

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      ## 削除予約
      t.datetime :destroy_requested_at
      t.datetime :destroy_schedule_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true, name: 'index_users1'
    add_index :users, :reset_password_token, unique: true, name: 'index_users2'
    add_index :users, :confirmation_token,   unique: true, name: 'index_users3'
    add_index :users, :unlock_token,         unique: true, name: 'index_users4'
    add_index :users, :code,                 unique: true, name: 'index_users5'
    add_index :users, :destroy_schedule_at,                name: 'index_users6'
  end
end
