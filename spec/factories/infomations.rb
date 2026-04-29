FactoryBot.define do
  factory :infomation do
    locale           { [*Settings.locales.keys, nil].sample }
    label            { Infomation.labels.keys.sample }
    sequence(:title) { |n| "お知らせ(#{n})" }
    summary          { Faker::Lorem.sentence }
    body             { [Faker::Lorem.paragraphs.join("\n"), nil].sample }
    started_at       { Faker::Time.between(from: 1.year.ago, to: 1.minute.ago) }
    ended_at         { [Faker::Time.between(from: 1.hour.from_now, to: 1.year.from_now), nil].sample }
    target           { :all }
    # force_started_at { nil }
    # force_ended_at   { nil }

    # 地域
    trait :all_locale do
      locale { nil }
    end
    trait :my_locale do
      locale { I18n.locale }
    end
    trait :other_locale do
      locale { (Settings.locales.keys - [I18n.locale]).sample }
    end

    # 対象
    trait :all do
      # target { :all }
    end
    trait :user do
      target { :user }
      association :user
    end

    # 表示期間
    trait :period_inside do
      # started_at { Faker::Time.between(from: 1.year.ago, to: 1.minute.ago) }
      # ended_at   { [Faker::Time.between(from: 1.hour.from_now, to: 1.year.from_now), nil].sample }
    end
    trait :period_finished do
      # started_at { Faker::Time.between(from: 1.year.ago, to: 1.minute.ago) }
      ended_at   { Faker::Time.between(from: started_at, to: 1.second.ago) }
    end
    trait :period_before do
      started_at { Faker::Time.between(from: 1.hour.from_now, to: 1.year.from_now) }
      ended_at   { [Faker::Time.between(from: started_at, to: 1.year.from_now), nil].sample }
    end

    # 強制表示期間
    trait :force_period_not_set do
      # force_started_at { nil }
      # force_ended_at   { nil }
    end
    trait :force_period_inside do
      force_started_at { Faker::Time.between(from: started_at, to: 1.minute.ago) }
      force_ended_at   { Faker::Time.between(from: 1.hour.from_now, to: ended_at || 1.year.from_now) }
    end
    trait :force_period_finished do
      force_started_at { Faker::Time.between(from: started_at, to: 1.minute.ago) }
      force_ended_at   { Faker::Time.between(from: force_started_at, to: 1.second.ago) }
    end
    trait :force_period_before do
      force_started_at { Faker::Time.between(from: 1.hour.from_now, to: 1.year.from_now) }
      force_ended_at   { Faker::Time.between(from: force_started_at, to: ended_at || 1.year.from_now) }
    end
  end
end
