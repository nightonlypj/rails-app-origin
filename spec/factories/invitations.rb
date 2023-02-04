FactoryBot.define do
  factory :invitation do
    code            { Digest::MD5.hexdigest(SecureRandom.uuid).to_i(16).to_s(36).rjust(25, '0') }
    domains         { [Faker::Internet.domain_name].to_s }
    power           { :admin }
    sequence(:memo) { |n| "memo(#{n})" }
    association :space
    association :created_user, factory: :user

    trait :create do
      domains { Faker::Internet.domain_name }
    end
    trait :create_max do
      domains do
        result = []
        domain = Faker::Internet.domain_name
        (1..Settings.invitation_domains_max_count).each do |index|
          result.push("#{index}.#{domain}")
        end

        result.join("\n")
      end
    end

    trait :domains do
      # domains { [Faker::Internet.domain_name].to_s }
    end
    trait :email do
      email   { Faker::Internet.safe_email }
      domains { nil }
    end

    trait :active do
      # ended_at { nil }
      # destroy_requested_at { nil }
      # destroy_schedule_at  { nil }
      # email_joined_at { nil }
    end
    trait :expired do
      ended_at { Time.current - 1.minute }
      # destroy_requested_at { nil }
      # destroy_schedule_at  { nil }
    end
    trait :deleted do
      destroy_requested_at { Time.current - 1.minute }
      destroy_schedule_at  { destroy_requested_at + Settings.space_destroy_schedule_days.days }
      # email_joined_at { nil }
    end
    trait :email_joined do
      email   { Faker::Internet.safe_email }
      domains { nil }
      email_joined_at { Time.current }
    end
  end
end
