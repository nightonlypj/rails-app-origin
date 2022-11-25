FactoryBot.define do
  factory :download do
    requested_at { Time.current }
    model        { :member }
    target       { :all }
    format       { :csv }
    char_code    { :sjis }
    newline_code { :crlf }
    output_items { ['user.name'] }
    association :user

    trait :success do
      status { :success }
    end
    trait :complete do
      status             { :success }
      last_downloaded_at { Time.current }
    end
  end
end
