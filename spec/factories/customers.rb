FactoryBot.define do
  factory :customer do
    code            { Zlib.crc32(SecureRandom.uuid) }
    sequence(:name) { |n| "customer#{n}test" }
  end
end
