FactoryBot.define do
  factory :download do
    requested_at { Time.current }
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
      completed_at { Time.current }
    end
    trait :failure do
      status        { :failure }
      error_message { 'エラー内容' }
      completed_at  { Time.current }
    end

    trait :downloaded do
      status             { :success }
      completed_at       { Time.current }
      last_downloaded_at { Time.current }
    end
  end
end
