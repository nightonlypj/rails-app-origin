FactoryBot.define do
  factory :customer do
    sequence(:code) { |n| "c#{n}test" }
    name            { "顧客(#{code})" }
  end
end
