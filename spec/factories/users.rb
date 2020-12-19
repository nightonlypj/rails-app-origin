FactoryBot.define do
  factory :user do
    pass = Faker::Internet.password(min_length: 8)
    sequence(:name)       { |n| "user#{n}test" }
    email                 { Faker::Internet.email }
    password              { pass }
    password_confirmation { pass }
    confirmed_at          { '0000-01-01' }
  end
end
