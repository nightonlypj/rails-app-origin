# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_08_06_000715) do

  create_table "admin_users", charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "name", null: false, comment: "氏名"
    t.string "email", default: "", null: false, comment: "メールアドレス"
    t.string "encrypted_password", default: "", null: false, comment: "暗号化されたパスワード"
    t.string "reset_password_token", comment: "パスワードリセットトークン"
    t.datetime "reset_password_sent_at", comment: "パスワードリセット送信日時"
    t.datetime "remember_created_at", comment: "ログイン状態維持開始日時"
    t.integer "sign_in_count", default: 0, null: false, comment: "ログイン回数"
    t.datetime "current_sign_in_at", comment: "現在のログイン日時"
    t.datetime "last_sign_in_at", comment: "最終ログイン日時"
    t.string "current_sign_in_ip", comment: "現在のログインIPアドレス"
    t.string "last_sign_in_ip", comment: "最終ログインIPアドレス"
    t.string "confirmation_token", comment: "メールアドレス確認トークン"
    t.datetime "confirmed_at", comment: "メールアドレス確認日時"
    t.datetime "confirmation_sent_at", comment: "メールアドレス確認送信日時"
    t.string "unconfirmed_email", comment: "確認待ちメールアドレス"
    t.integer "failed_attempts", default: 0, null: false, comment: "連続ログイン失敗回数"
    t.string "unlock_token", comment: "アカウントロック解除トークン"
    t.datetime "locked_at", comment: "アカウントロック日時"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_admin_users3", unique: true
    t.index ["email"], name: "index_admin_users1", unique: true
    t.index ["reset_password_token"], name: "index_admin_users2", unique: true
    t.index ["unlock_token"], name: "index_admin_users4", unique: true
  end

  create_table "infomations", charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "title", null: false, comment: "タイトル"
    t.string "summary", comment: "概要"
    t.text "body", comment: "本文"
    t.datetime "started_at", null: false, comment: "開始日時"
    t.datetime "ended_at", comment: "終了日時"
    t.integer "target", null: false, comment: "対象"
    t.bigint "user_id", comment: "ユーザーID"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["started_at", "ended_at"], name: "index_infomations2"
    t.index ["started_at", "id"], name: "index_infomations1"
    t.index ["target", "user_id"], name: "index_infomations3"
    t.index ["user_id"], name: "index_infomations_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "code", null: false, comment: "ユーザーコード"
    t.string "image", comment: "画像"
    t.string "name", null: false, comment: "氏名"
    t.string "email", default: "", null: false, comment: "メールアドレス"
    t.string "encrypted_password", default: "", null: false, comment: "暗号化されたパスワード"
    t.string "reset_password_token", comment: "パスワードリセットトークン"
    t.datetime "reset_password_sent_at", comment: "パスワードリセット送信日時"
    t.datetime "remember_created_at", comment: "ログイン状態維持開始日時"
    t.integer "sign_in_count", default: 0, null: false, comment: "ログイン回数"
    t.datetime "current_sign_in_at", comment: "現在のログイン日時"
    t.datetime "last_sign_in_at", comment: "最終ログイン日時"
    t.string "current_sign_in_ip", comment: "現在のログインIPアドレス"
    t.string "last_sign_in_ip", comment: "最終ログインIPアドレス"
    t.string "confirmation_token", comment: "メールアドレス確認トークン"
    t.datetime "confirmed_at", comment: "メールアドレス確認日時"
    t.datetime "confirmation_sent_at", comment: "メールアドレス確認送信日時"
    t.string "unconfirmed_email", comment: "確認待ちメールアドレス"
    t.integer "failed_attempts", default: 0, null: false, comment: "連続ログイン失敗回数"
    t.string "unlock_token", comment: "アカウントロック解除トークン"
    t.datetime "locked_at", comment: "アカウントロック日時"
    t.datetime "destroy_requested_at", comment: "削除依頼日時"
    t.datetime "destroy_schedule_at", comment: "削除予定日時"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "provider", default: "email", null: false, comment: "認証方法"
    t.string "uid", default: "", null: false, comment: "UID"
    t.boolean "allow_password_change", default: false, comment: "パスワード変更許可"
    t.string "nickname", comment: "ニックネーム"
    t.text "tokens", comment: "トークン"
    t.index ["code"], name: "index_users5", unique: true
    t.index ["confirmation_token"], name: "index_users3", unique: true
    t.index ["destroy_schedule_at"], name: "index_users6"
    t.index ["email"], name: "index_users1", unique: true
    t.index ["reset_password_token"], name: "index_users2", unique: true
    t.index ["uid", "provider"], name: "index_users7", unique: true
    t.index ["unlock_token"], name: "index_users4", unique: true
  end

  create_table "versions", charset: "utf8mb4", collation: "utf8mb4_bin", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions1"
  end

  add_foreign_key "infomations", "users"
end
