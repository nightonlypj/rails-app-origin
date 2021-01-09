FactoryBot.define do
  factory :user do
    pass = Faker::Internet.password(min_length: 8)
    code                  { Digest::MD5.hexdigest(SecureRandom.uuid) }
    sequence(:name)       { |n| "user#{n}test" }
    email                 { Faker::Internet.email }
    password              { pass }
    password_confirmation { pass }
    confirmed_at          { '0000-01-01 00:00:00+0000' }
  end
end
