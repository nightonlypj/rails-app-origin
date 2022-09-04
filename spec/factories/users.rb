FactoryBot.define do
  factory :user do
    code               { Digest::MD5.hexdigest(SecureRandom.uuid).to_i(16).to_s(36).rjust(25, '0') }
    sequence(:name)    { |n| "user(#{n})" }
    email              { Faker::Internet.safe_email(name: "#{name}#{Faker::Number.hexadecimal(digits: 3)}") }
    password           { Faker::Internet.password(min_length: 8) }
    confirmed_at       { '0000-01-01 00:00:00+0000' }
    sign_in_count      { 1 }
    current_sign_in_at { Time.now.utc - 1.hour }
    last_sign_in_at    { Time.now.utc - 2.hours }
    current_sign_in_ip { Faker::Internet.ip_v4_address }
    last_sign_in_ip    { Faker::Internet.ip_v4_address }

    # ロック中
    trait :locked do
      unlock_token    { Devise.token_generator.digest(self, :unlock_token, email) }
      locked_at       { Time.now.utc - 1.minute }
      failed_attempts { Devise.maximum_attempts }
    end

    # ロック前
    trait :before_lock1 do
      failed_attempts { Devise.maximum_attempts - 1 }
    end

    # ロック前の前
    trait :before_lock2 do
      failed_attempts { Devise.maximum_attempts - 2 }
    end

    # ロック前の前の前
    trait :before_lock3 do
      failed_attempts { Devise.maximum_attempts - 3 }
    end

    # メール未確認
    trait :unconfirmed do
      confirmation_token   { Devise.token_generator.digest(self, :confirmation_token, email) }
      confirmation_sent_at { Time.now.utc - 1.minute }
      confirmed_at         { nil }
    end

    # メールアドレス変更中
    trait :email_changed do
      confirmation_token   { Devise.token_generator.digest(self, :confirmation_token, email) }
      confirmation_sent_at { Time.now.utc - 1.minute }
      unconfirmed_email    { Faker::Internet.safe_email }
    end

    # メールアドレス変更期限切れ
    trait :expired_email_change do
      confirmation_token   { Devise.token_generator.digest(self, :confirmation_token, email) }
      confirmation_sent_at { Time.now.utc - User.confirm_within - 1.minute }
      unconfirmed_email    { Faker::Internet.safe_email }
    end

    # 削除予約済み
    trait :destroy_reserved do
      destroy_requested_at { Time.current - 1.minute }
      destroy_schedule_at  { destroy_requested_at + Settings['destroy_schedule_days'].days }
    end

    # 削除対象
    trait :destroy_targeted do
      destroy_requested_at { Time.current - 1.minute - Settings['destroy_schedule_days'].days }
      destroy_schedule_at  { destroy_requested_at + Settings['destroy_schedule_days'].days }
    end
  end
end
