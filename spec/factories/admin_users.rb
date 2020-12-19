FactoryBot.define do
  factory :admin_user do
    pass = Faker::Internet.password(min_length: 8)
    sequence(:name)       { |n| "admin_user#{n}test" }
    email                 { Faker::Internet.email }
    password              { pass }
    password_confirmation { pass }
    confirmed_at          { '0000-01-01' }
  end
end
