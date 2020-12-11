FactoryBot.define do
  factory :space do
    sequence(:sort_key) { |n| n }
    subdomain           { "myspace#{sort_key}" }
    name                { "マイスペース(#{sort_key})" }
  end
end
