FactoryBot.define do
  factory :member do
    power { :admin }
    association :space
    association :user
    association :invitationed_user, factory: :user
    association :last_updated_user, factory: :user

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
