FactoryBot.define do
  factory :infomation do
    label            { :not }
    sequence(:title) { |n| "infomation(#{n})" }
    summary          { "#{title}の要約" }
    body             { "#{title}の本文" }
    started_at       { Time.current - 1.hour }
    ended_at         { Time.current + 3.hour }
    target           { :all }

    # 全員
    trait :all do
      target { :all }
    end

    # 対象ユーザーのみ
    trait :user do
      target { :user }
    end

    # 終了なし
    trait :forever do
      label    { :hindrance }
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
      label            { :maintenance }
      force_started_at { Time.current }
      force_ended_at   { Time.current + 2.hour }
    end

    # 大切なお知らせ: 終了なし
    trait :force_forever do
      label          { :other }
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
