FactoryBot.define do
  factory :infomation do
    title { 'MyString' }
    body { 'MyText' }
    target { 1 }
    user { nil }
  end
end
