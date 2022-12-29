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

ActiveRecord::Schema.define(version: 2022_12_22_110420) do

  create_table "admin_users", charset: "utf8", collation: "utf8_bin", comment: "管理者", force: :cascade do |t|
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

  create_table "download_files", charset: "utf8", collation: "utf8_bin", comment: "ダウンロードファイル", force: :cascade do |t|
    t.bigint "download_id", null: false, comment: "ダウンロードID"
    t.binary "body", size: :long, comment: "内容"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["download_id"], name: "index_download_files_on_download_id"
  end

  create_table "downloads", charset: "utf8", collation: "utf8_bin", comment: "ダウンロード", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "ユーザーID"
    t.integer "status", default: 0, null: false, comment: "ステータス"
    t.datetime "requested_at", null: false, comment: "依頼日時"
    t.datetime "completed_at", comment: "完了日時"
    t.string "error_message", comment: "エラーメッセージ"
    t.datetime "last_downloaded_at", comment: "最終ダウンロード日時"
    t.integer "model", null: false, comment: "モデル"
    t.bigint "space_id", comment: "スペースID"
    t.integer "target", null: false, comment: "対象"
    t.integer "format", null: false, comment: "形式"
    t.integer "char_code", null: false, comment: "文字コード"
    t.integer "newline_code", null: false, comment: "改行コード"
    t.text "output_items", comment: "出力項目"
    t.text "select_items", comment: "選択項目"
    t.text "search_params", comment: "検索パラメータ"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["completed_at"], name: "index_downloads2"
    t.index ["space_id"], name: "index_downloads_on_space_id"
    t.index ["user_id", "requested_at"], name: "index_downloads1"
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "infomations", charset: "utf8", collation: "utf8_bin", comment: "お知らせ", force: :cascade do |t|
    t.string "title", null: false, comment: "タイトル"
    t.string "summary", comment: "概要"
    t.text "body", comment: "本文"
    t.datetime "started_at", null: false, comment: "開始日時"
    t.datetime "ended_at", comment: "終了日時"
    t.integer "target", null: false, comment: "対象"
    t.bigint "user_id", comment: "ユーザーID"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "label", default: 0, null: false, comment: "ラベル"
    t.datetime "force_started_at", comment: "強制表示開始日時"
    t.datetime "force_ended_at", comment: "強制表示終了日時"
    t.index ["force_started_at", "force_ended_at"], name: "index_infomations4"
    t.index ["started_at", "ended_at"], name: "index_infomations2"
    t.index ["started_at", "id"], name: "index_infomations1"
    t.index ["target", "user_id"], name: "index_infomations3"
    t.index ["user_id"], name: "index_infomations_on_user_id"
  end

  create_table "invitations", charset: "utf8", collation: "utf8_bin", comment: "招待", force: :cascade do |t|
    t.string "code", null: false, comment: "コード"
    t.bigint "space_id", null: false, comment: "スペースID"
    t.text "domains", comment: "ドメイン"
    t.string "email", comment: "メールアドレス"
    t.integer "power", null: false, comment: "権限"
    t.string "memo", comment: "メモ"
    t.datetime "ended_at", comment: "終了日時"
    t.datetime "deleted_at", comment: "削除日時"
    t.bigint "created_user_id", null: false, comment: "作成者ID"
    t.bigint "last_updated_user_id", comment: "最終更新者ID"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_invitations1", unique: true
    t.index ["created_at", "id"], name: "index_invitations9"
    t.index ["created_user_id", "id"], name: "index_invitations7"
    t.index ["created_user_id"], name: "index_invitations_on_created_user_id"
    t.index ["deleted_at", "id"], name: "index_invitations6"
    t.index ["domains"], name: "index_invitations2", length: 1024
    t.index ["email"], name: "index_invitations3"
    t.index ["ended_at", "id"], name: "index_invitations5"
    t.index ["last_updated_user_id", "id"], name: "index_invitations8"
    t.index ["last_updated_user_id"], name: "index_invitations_on_last_updated_user_id"
    t.index ["space_id", "power", "id"], name: "index_invitations4"
    t.index ["space_id"], name: "index_invitations_on_space_id"
    t.index ["updated_at", "id"], name: "index_invitations10"
  end

  create_table "members", charset: "utf8", collation: "utf8_bin", comment: "メンバー", force: :cascade do |t|
    t.bigint "space_id", null: false, comment: "スペースID"
    t.bigint "user_id", null: false, comment: "ユーザーID"
    t.integer "power", null: false, comment: "権限"
    t.bigint "invitationed_user_id", comment: "招待者ID"
    t.bigint "last_updated_user_id", comment: "最終更新者ID"
    t.datetime "invitationed_at", comment: "招待日時"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at", "id"], name: "index_members6"
    t.index ["invitationed_at", "id"], name: "index_members5"
    t.index ["invitationed_user_id", "id"], name: "index_members3"
    t.index ["invitationed_user_id"], name: "index_members_on_invitationed_user_id"
    t.index ["last_updated_user_id", "id"], name: "index_members4"
    t.index ["last_updated_user_id"], name: "index_members_on_last_updated_user_id"
    t.index ["space_id", "power", "id"], name: "index_members2"
    t.index ["space_id", "user_id"], name: "index_members1", unique: true
    t.index ["space_id"], name: "index_members_on_space_id"
    t.index ["updated_at", "id"], name: "index_members7"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "spaces", charset: "utf8", collation: "utf8_bin", comment: "スペース", force: :cascade do |t|
    t.string "code", null: false, comment: "コード"
    t.string "image", comment: "画像"
    t.string "name", null: false, comment: "名称"
    t.text "description", comment: "説明"
    t.boolean "private", default: true, null: false, comment: "非公開"
    t.datetime "destroy_requested_at", comment: "削除依頼日時"
    t.datetime "destroy_schedule_at", comment: "削除予定日時"
    t.bigint "created_user_id", null: false, comment: "作成者ID"
    t.bigint "last_updated_user_id", comment: "最終更新者ID"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_spaces1", unique: true
    t.index ["created_at", "id"], name: "index_spaces3"
    t.index ["created_user_id"], name: "index_spaces_on_created_user_id"
    t.index ["destroy_schedule_at"], name: "index_spaces2"
    t.index ["last_updated_user_id"], name: "index_spaces_on_last_updated_user_id"
    t.index ["name", "id"], name: "index_spaces4"
  end

  create_table "users", charset: "utf8", collation: "utf8_bin", comment: "ユーザー", force: :cascade do |t|
    t.string "code", null: false, comment: "コード"
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
    t.boolean "allow_password_change", default: false, comment: "パスワード再設定中"
    t.text "tokens", comment: "認証トークン"
    t.datetime "infomation_check_last_started_at", comment: "お知らせ確認最終開始日時"
    t.index ["code"], name: "index_users5", unique: true
    t.index ["confirmation_token"], name: "index_users3", unique: true
    t.index ["destroy_schedule_at"], name: "index_users6"
    t.index ["email"], name: "index_users1", unique: true
    t.index ["reset_password_token"], name: "index_users2", unique: true
    t.index ["uid", "provider"], name: "index_users7", unique: true
    t.index ["unlock_token"], name: "index_users4", unique: true
  end

  create_table "versions", charset: "utf8", collation: "utf8_bin", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :long
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions1"
  end

  add_foreign_key "download_files", "downloads"
  add_foreign_key "downloads", "users"
  add_foreign_key "infomations", "users"
  add_foreign_key "invitations", "spaces"
  add_foreign_key "members", "spaces"
  add_foreign_key "members", "users"
end
