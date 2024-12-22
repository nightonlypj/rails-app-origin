FactoryBot.define do
  factory :space do
    sequence(:code)        { |n| Faker::Number.hexadecimal(digits: 3) + n.to_s.rjust(5, '0') }
    sequence(:name)        { |n| "space(#{n})" }
    sequence(:description) { |n| "description(#{n})" }
    private                { true }
    association :created_user, factory: :user

    # 非公開・公開
    trait :private do
      # private { true }
    end
    trait :public do
      private { false }
    end

    # 削除予約済み
    trait :destroy_reserved do
      destroy_requested_at { Time.current - 1.minute }
      destroy_schedule_at  { destroy_requested_at + Settings.space_destroy_schedule_days.days }
    end

    # 削除対象
    trait :destroy_targeted do
      destroy_requested_at { Time.current - 1.minute - Settings.space_destroy_schedule_days.days }
      destroy_schedule_at  { destroy_requested_at + Settings.space_destroy_schedule_days.days }
    end
  end
end