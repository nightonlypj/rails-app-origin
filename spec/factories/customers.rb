FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "顧客(#{n})" }
  end
end
