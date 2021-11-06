FactoryBot.define do
  factory :admin_user do
    pass = Faker::Internet.password(min_length: 8)
    sequence(:name)       { |n| "admin(#{n})" }
    email                 { Faker::Internet.safe_email(name: name) }
    password              { pass }
    password_confirmation { pass }
    confirmed_at          { '0000-01-01 00:00:00+0000' }
  end

  # ロック中
  factory :admin_user_locked, parent: :admin_user do
    unlock_token    { Devise.token_generator.digest(self, :unlock_token, email) }
    locked_at       { Time.now.utc - 1.minute }
    failed_attempts { Devise.maximum_attempts }
  end
end
