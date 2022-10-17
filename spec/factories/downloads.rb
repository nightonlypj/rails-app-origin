FactoryBot.define do
  factory :download do
    requested_at { Time.current }
    model        { :member }
    target       { :all }
    format       { :csv }
    char         { :sjis }
    newline      { :crlf }
    association :user

    # メンバー
    trait :member do
      model { :member }
      association :space
    end
  end
end
