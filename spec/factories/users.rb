FactoryBot.define do
  factory :user do
    code               { Utils::UniqueCodeGenerator.base36_uuid }
    name               { Faker::Japanese::Name.name.truncate(Settings.user_name_maximum) }
    sequence(:email)   { |n| Faker::Internet.email(name: "user#{n}") }
    password           { Faker::Internet.password(min_length: Devise.password_length.min) }
    confirmed_at       { Faker::Date.backward(days: 365) }
    sign_in_count      { Faker::Number.between(from: 1, to: 1_000) }
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

    # ロック前（残り1回）
    trait :before_lock1 do
      failed_attempts { Devise.maximum_attempts - 1 }
    end

    # ロック前（残り2回）
    trait :before_lock2 do
      failed_attempts { Devise.maximum_attempts - 2 }
    end

    # ロック前（残り3回）
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
      unconfirmed_email    { Faker::Internet.email }
    end

    # メールアドレス変更期限切れ
    trait :expired_email_change do
      confirmation_token   { Devise.token_generator.digest(self, :confirmation_token, email) }
      confirmation_sent_at { Time.now.utc - User.confirm_within - 1.minute }
      unconfirmed_email    { Faker::Internet.email }
    end

    # 削除予約済み
    trait :destroy_reserved do
      destroy_requested_at { Faker::Time.backward(days: Settings.user_destroy_schedule_days.days) }
      destroy_schedule_at  { destroy_requested_at + Settings.user_destroy_schedule_days.days }
    end

    # 削除対象
    trait :destroy_targeted do
      destroy_requested_at { Faker::Time.between(from: 1.year.ago, to: Settings.user_destroy_schedule_days.days.ago - 1.second) }
      destroy_schedule_at  { destroy_requested_at + Settings.user_destroy_schedule_days.days }
    end
  end
end
