FactoryBot.define do
  factory :download do
    requested_at { Time.current - 2.hours }
    # status       { :waiting }
    model        { :member }
    target       { :all }
    format       { :csv }
    char_code    { :sjis }
    newline_code { :crlf }
    output_items { ['user.name'] }
    association :user

    # ステータス
    trait :waiting do
      # status { :waiting }
    end
    trait :processing do
      status { :processing }
    end
    trait :success do
      status       { :success }
      completed_at { Time.current - 1.hour }
    end
    trait :failure do
      status        { :failure }
      error_message { 'エラー内容' }
      completed_at  { Time.current - 1.hour }
    end

    trait :downloaded do
      status             { :success }
      completed_at       { Time.current - 1.hour }
      last_downloaded_at { Time.current }
    end
  end
end
