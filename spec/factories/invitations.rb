FactoryBot.define do
  factory :invitation do
    code            { Utils::UniqueCodeGenerator.base36_uuid }
    domains         { [Faker::Internet.domain_name].to_s }
    power           { :admin }
    sequence(:memo) { |n| "memo(#{n})" }
    association :space
    association :created_user, factory: :user

    trait :domains do
      # domains { [Faker::Internet.domain_name].to_s }
    end
    trait :email do
      email   { Faker::Internet.email }
      domains { nil }
    end

    # ステータス
    trait :active do
      # ended_at { nil }
      # destroy_requested_at { nil }
      # destroy_schedule_at  { nil }
      # email_joined_at { nil }
    end
    trait :expired do
      ended_at { 1.minute.ago }
      # destroy_requested_at { nil }
      # destroy_schedule_at  { nil }
    end
    trait :deleted do
      destroy_requested_at { 1.minute.ago }
      destroy_schedule_at  { destroy_requested_at + Settings.space_destroy_schedule_days.days }
      # email_joined_at { nil }
    end
    trait :email_joined do
      email   { Faker::Internet.email }
      domains { nil }
      email_joined_at { Time.current }
    end
  end
end
