FactoryBot.define do
  factory :holiday do
    date { Time.zone.today }
    name { "holiday(#{I18n.l(date)})" }
  end
end
