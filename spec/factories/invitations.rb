FactoryBot.define do
  factory :invitation do
    code            { Digest::MD5.hexdigest(SecureRandom.uuid).to_i(16).to_s(36).rjust(25, '0') }
    domains         { Faker::Internet.domain_name }
    power           { :admin }
    sequence(:memo) { |n| "memo(#{n})" }
    association :space
    association :created_user, factory: :user

    trait :domain do
      # domains { Faker::Internet.domain_name }
    end
    trait :domains do
      domains { "#{Faker::Internet.domain_name}\n#{Faker::Internet.domain_name}\n" }
    end
    trait :email do
      email { Faker::Internet.safe_email }
    end
  end
end
