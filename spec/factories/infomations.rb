FactoryBot.define do
  factory :infomation do
    sequence(:title) { |n| "お知らせ(#{n})" }
    body             { "#{title}の本文" }
    started_at       { Time.current }
    ended_at         { nil }
    target           { :All }
    user             { nil }
  end
end
