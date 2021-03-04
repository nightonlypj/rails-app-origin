FactoryBot.define do
  factory :space do
    sequence(:subdomain) { |n| "space#{n}name" }
    name                 { "#{subdomain}のスペース名" }
    purpose              { "#{subdomain}の目的" }
  end
end
