FactoryBot.define do
  factory :admin_user do
    pass = Faker::Internet.password(min_length: 8)
    email                 { Faker::Internet.email }
    password              { pass }
    password_confirmation { pass }
  end
end
