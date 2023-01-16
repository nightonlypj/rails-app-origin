FactoryBot.define do
  factory :member do
    power { :admin }
    association :space
    association :user

    # 権限
    trait :admin do
      # power { :admin }
    end
    trait :writer do
      power { :writer }
    end
    trait :reader do
      power { :reader }
    end
  end
end
