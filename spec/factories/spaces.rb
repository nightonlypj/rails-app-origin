FactoryBot.define do
  factory :space do
    sequence(:subdomain) { |n| "myspace#{n}" }
    name                 { "マイスペース(#{subdomain})" }
  end
end
