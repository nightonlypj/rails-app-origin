FactoryBot.define do
  factory :infomation do
    sequence(:title) { |n| "お知らせ(#{n})" }
    summary          { "#{title}の要約" }
    body             { "#{title}の本文" }
    started_at       { Time.current }
    ended_at         { nil }
    target           { :All }
    target_user_id   { nil }
  end
end
