FactoryBot.define do
  factory :holiday do
    date { Faker::Date.between(from: 1.year.ago, to: 1.year.from_now) }
    name { "祝日(#{I18n.l(date)})" }
  end
end
