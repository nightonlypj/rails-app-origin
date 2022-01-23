FactoryBot.define do
  factory :infomation do
    label            { :Not }
    sequence(:title) { |n| "infomation(#{n})" }
    summary          { "#{title}の要約" }
    body             { "#{title}の本文" }
    started_at       { Time.current - 1.hour }
    ended_at         { Time.current + 3.hour }
    target           { :All }
  end

  # 終了なし
  factory :infomation_forever, parent: :infomation do
    label    { :Hindrance }
    ended_at { nil }
  end

  # 終了済み
  factory :infomation_finished, parent: :infomation do
    ended_at { Time.current - 1.second }
  end

  # 予約（終了あり）
  factory :infomation_reserve, parent: :infomation do
    started_at { Time.current + 1.hour }
  end

  # 予約（終了なし）
  factory :infomation_reserve_forever, parent: :infomation_reserve do
    ended_at { nil }
  end

  # 大切なお知らせ
  factory :infomation_important, parent: :infomation do
    label            { :Maintenance }
    force_started_at { Time.current }
    force_ended_at   { Time.current + 2.hour }
  end

  # 大切なお知らせ: 終了なし
  factory :infomation_important_forever, parent: :infomation_important do
    label          { :Other }
    ended_at       { nil }
    force_ended_at { nil }
  end

  # 大切なお知らせ: 終了済み
  factory :infomation_important_finished, parent: :infomation_important do
    force_ended_at { Time.current - 1.second }
  end

  # 大切なお知らせ: 予約（終了あり）
  factory :infomation_important_reserve, parent: :infomation_important do
    force_started_at { Time.current + 1.hour }
  end

  # 大切なお知らせ: 予約（終了なし）
  factory :infomation_important_reserve_forever, parent: :infomation_important_reserve do
    force_ended_at { nil }
  end
end
