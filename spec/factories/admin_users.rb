FactoryBot.define do
  factory :admin_user do
    sequence(:name) { |n| "admin(#{n})" }
    email           { Faker::Internet.email(name: "#{name}#{Faker::Number.hexadecimal(digits: 3)}") }
    password        { Faker::Internet.password(min_length: 8) }
    confirmed_at    { '0000-01-01 00:00:00+0000' }

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
  end
end
