FactoryBot.define do
  factory :infomation do
    label            { :Not }
    sequence(:title) { |n| "infomation(#{n})" }
    summary          { "#{title}の要約" }
    body             { "#{title}の本文" }
    started_at       { Time.current - 1.hour }
    ended_at         { Time.current + 3.hour }
    target           { :All }

    # 終了なし
    trait :forever do
      label    { :Hindrance }
      ended_at { nil }
    end

    # 終了済み
    trait :finished do
      ended_at { Time.current - 1.second }
    end

    # 予約（終了あり）
    trait :reserve do
      started_at { Time.current + 1.hour }
    end

    # 予約（終了なし）
    trait :reserve_forever do
      started_at { Time.current + 1.hour }
      ended_at { nil }
    end

    # 大切なお知らせ
    trait :important do
      label            { :Maintenance }
      force_started_at { Time.current }
      force_ended_at   { Time.current + 2.hour }
    end

    # 大切なお知らせ: 終了なし
    trait :force_forever do
      label          { :Other }
      ended_at       { nil }
      force_ended_at { nil }
    end

    # 大切なお知らせ: 終了済み
    trait :force_finished do
      force_ended_at { Time.current - 1.second }
    end

    # 大切なお知らせ: 予約（終了あり）
    trait :force_reserve do
      force_started_at { Time.current + 1.hour }
    end

    # 大切なお知らせ: 予約（終了なし）
    trait :force_reserve_forever do
      force_started_at { Time.current + 1.hour }
      force_ended_at   { nil }
    end
  end
end
