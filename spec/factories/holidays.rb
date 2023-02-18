FactoryBot.define do
  factory :holiday do
    date { Time.current }
    name { "祝日(#{I18n.l(date.to_date)})" }
  end
end
