FactoryBot.define do
  factory :member do
    power { :Admin }
    association :space
    association :user

    # 権限
    trait :admin do
      power { :Admin }
    end
    trait :writer do
      power { :Writer }
    end
    trait :reader do
      power { :Reader }
    end
  end
end
