FactoryBot.define do
  factory :admin_user do
    pass = Faker::Internet.password(min_length: 8)
    name                  { Faker::Internet.username(specifier: Settings['user_name_minimum']..Settings['user_name_maximum']) }
    email                 { Faker::Internet.email }
    password              { pass }
    password_confirmation { pass }
    confirmed_at          { '0000-01-01' }
  end
end
