FactoryBot.define do
  factory :admin_user do
    name             { Faker::Japanese::Name.name.truncate(Settings.user_name_maximum) }
    sequence(:email) { |n| Faker::Internet.email(name: "admin#{n}") }
    password         { Faker::Internet.password(min_length: Devise.password_length.min) }
    confirmed_at     { Faker::Date.backward(days: 365) }

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
  end
end
