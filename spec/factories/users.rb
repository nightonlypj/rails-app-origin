FactoryBot.define do
  factory :user do
    pass = Faker::Internet.password(min_length: 8)
    code                  { Digest::MD5.hexdigest(SecureRandom.uuid) }
    sequence(:name)       { |n| "user(#{n})" }
    email                 { Faker::Internet.safe_email(name: name) }
    password              { pass }
    password_confirmation { pass }
    confirmed_at          { '0000-01-01 00:00:00+0000' }
    sign_in_count         { 1 }
    current_sign_in_at    { Time.now.utc - 1.hour }
    last_sign_in_at       { Time.now.utc - 2.hours }
    current_sign_in_ip    { Faker::Internet.ip_v4_address }
    last_sign_in_ip       { Faker::Internet.ip_v4_address }
  end

  # ロック中
  factory :user_locked, parent: :user do
    unlock_token    { Devise.token_generator.digest(self, :unlock_token, email) }
    locked_at       { Time.now.utc - 1.minute }
    failed_attempts { Devise.maximum_attempts }
  end

  # ロック前
  factory :user_before_lock1, parent: :user do
    failed_attempts { Devise.maximum_attempts - 1 }
  end

  # ロック前の前
  factory :user_before_lock2, parent: :user do
    failed_attempts { Devise.maximum_attempts - 2 }
  end

  # メール未確認
  factory :user_unconfirmed, parent: :user do
    confirmation_token   { Devise.token_generator.digest(self, :confirmation_token, email) }
    confirmation_sent_at { Time.now.utc - 1.minute }
    confirmed_at         { nil }
  end

  # メールアドレス変更中
  factory :user_email_changed, parent: :user do
    confirmation_token   { Devise.token_generator.digest(self, :confirmation_token, email) }
    confirmation_sent_at { Time.now.utc - 1.minute }
    unconfirmed_email    { Faker::Internet.safe_email }
  end

  # 削除予約済み
  factory :user_destroy_reserved, parent: :user do
    destroy_requested_at { Time.current - 1.minute }
    destroy_schedule_at  { destroy_requested_at + Settings['destroy_schedule_days'].days }
  end

  # 削除対象
  factory :user_destroy_targeted, parent: :user do
    destroy_requested_at { Time.current - 1.minute - Settings['destroy_schedule_days'].days }
    destroy_schedule_at  { destroy_requested_at + Settings['destroy_schedule_days'].days }
  end
end
