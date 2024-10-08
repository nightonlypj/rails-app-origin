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

ActiveRecord::Schema[7.1].define(version: 2024_02_04_130621) do
  create_table "admin_users", charset: "utf8mb4", collation: "utf8mb4_general_ci", comment: "管理者", force: :cascade do |t|
    t.string "name", null: false, comment: "氏名"
    t.string "email", default: "", null: false, comment: "メールアドレス"
    t.string "encrypted_password", default: "", null: false, comment: "暗号化されたパスワード"
    t.string "reset_password_token", comment: "パスワードリセットトークン"
    t.datetime "reset_password_sent_at", precision: nil, comment: "パスワードリセット送信日時"
    t.datetime "remember_created_at", precision: nil, comment: "ログイン状態維持開始日時"
    t.integer "sign_in_count", default: 0, null: false, comment: "ログイン回数"
    t.datetime "current_sign_in_at", precision: nil, comment: "現在のログイン日時"
    t.datetime "last_sign_in_at", precision: nil, comment: "最終ログイン日時"
    t.string "current_sign_in_ip", comment: "現在のログインIPアドレス"
    t.string "last_sign_in_ip", comment: "最終ログインIPアドレス"
    t.string "confirmation_token", comment: "メールアドレス確認トークン"
    t.datetime "confirmed_at", precision: nil, comment: "メールアドレス確認日時"
    t.datetime "confirmation_sent_at", precision: nil, comment: "メールアドレス確認送信日時"
    t.string "unconfirmed_email", comment: "確認待ちメールアドレス"
    t.integer "failed_attempts", default: 0, null: false, comment: "連続ログイン失敗回数"
    t.string "unlock_token", comment: "アカウントロック解除トークン"
    t.datetime "locked_at", precision: nil, comment: "アカウントロック日時"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_admin_users3", unique: true
    t.index ["email"], name: "index_admin_users1", unique: true
    t.index ["reset_password_token"], name: "index_admin_users2", unique: true
    t.index ["unlock_token"], name: "index_admin_users4", unique: true
  end

  create_table "delayed_jobs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "holidays", charset: "utf8mb4", collation: "utf8mb4_general_ci", comment: "祝日", force: :cascade do |t|
    t.date "date", null: false, comment: "日付"
    t.string "name", null: false, comment: "名称"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_holidays1", unique: true
  end

  create_table "infomations", charset: "utf8mb4", collation: "utf8mb4_general_ci", comment: "お知らせ", force: :cascade do |t|
    t.string "title", null: false, comment: "タイトル"
    t.string "summary", comment: "概要"
    t.text "body", comment: "本文"
    t.datetime "started_at", precision: nil, null: false, comment: "開始日時"
    t.datetime "ended_at", precision: nil, comment: "終了日時"
    t.integer "target", null: false, comment: "対象"
    t.bigint "user_id", comment: "ユーザーID"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "label", default: 0, null: false, comment: "ラベル"
    t.datetime "force_started_at", precision: nil, comment: "強制表示開始日時"
    t.datetime "force_ended_at", precision: nil, comment: "強制表示終了日時"
    t.string "locale", comment: "地域"
    t.index ["force_started_at", "force_ended_at"], name: "index_infomations4"
    t.index ["locale"], name: "index_infomations5"
    t.index ["started_at", "ended_at"], name: "index_infomations2"
    t.index ["started_at", "id"], name: "index_infomations1"
    t.index ["target", "user_id"], name: "index_infomations3"
    t.index ["user_id"], name: "index_infomations_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", comment: "ユーザー", force: :cascade do |t|
    t.string "code", null: false, comment: "コード"
    t.string "image", comment: "画像"
    t.string "name", null: false, comment: "氏名"
    t.string "email", default: "", null: false, comment: "メールアドレス"
    t.string "encrypted_password", default: "", null: false, comment: "暗号化されたパスワード"
    t.string "reset_password_token", comment: "パスワードリセットトークン"
    t.datetime "reset_password_sent_at", precision: nil, comment: "パスワードリセット送信日時"
    t.datetime "remember_created_at", precision: nil, comment: "ログイン状態維持開始日時"
    t.integer "sign_in_count", default: 0, null: false, comment: "ログイン回数"
    t.datetime "current_sign_in_at", precision: nil, comment: "現在のログイン日時"
    t.datetime "last_sign_in_at", precision: nil, comment: "最終ログイン日時"
    t.string "current_sign_in_ip", comment: "現在のログインIPアドレス"
    t.string "last_sign_in_ip", comment: "最終ログインIPアドレス"
    t.string "confirmation_token", comment: "メールアドレス確認トークン"
    t.datetime "confirmed_at", precision: nil, comment: "メールアドレス確認日時"
    t.datetime "confirmation_sent_at", precision: nil, comment: "メールアドレス確認送信日時"
    t.string "unconfirmed_email", comment: "確認待ちメールアドレス"
    t.integer "failed_attempts", default: 0, null: false, comment: "連続ログイン失敗回数"
    t.string "unlock_token", comment: "アカウントロック解除トークン"
    t.datetime "locked_at", precision: nil, comment: "アカウントロック日時"
    t.datetime "destroy_requested_at", precision: nil, comment: "削除依頼日時"
    t.datetime "destroy_schedule_at", precision: nil, comment: "削除予定日時"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider", default: "email", null: false, comment: "認証方法"
    t.string "uid", default: "", null: false, comment: "UID"
    t.boolean "allow_password_change", default: false, comment: "パスワード再設定中"
    t.text "tokens", comment: "認証トークン"
    t.datetime "infomation_check_last_started_at", precision: nil, comment: "お知らせ確認最終開始日時"
    t.index ["code"], name: "index_users5", unique: true
    t.index ["confirmation_token"], name: "index_users3", unique: true
    t.index ["destroy_schedule_at"], name: "index_users6"
    t.index ["email"], name: "index_users1", unique: true
    t.index ["reset_password_token"], name: "index_users2", unique: true
    t.index ["uid", "provider"], name: "index_users7", unique: true
    t.index ["unlock_token"], name: "index_users4", unique: true
  end

  create_table "versions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions1"
  end

  add_foreign_key "infomations", "users"
end
