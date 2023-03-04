FactoryBot.define do
  factory :holiday do
    date { Time.current.to_date }
    name { "holiday(#{I18n.l(date)})" }
  end
end
