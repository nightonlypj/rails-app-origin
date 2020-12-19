FactoryBot.define do
  factory :customer do
    sequence(:code) { |n| "customer#{n}test" }
    name            { "顧客(#{code})" }
  end
end
