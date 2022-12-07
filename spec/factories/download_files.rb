FactoryBot.define do
  factory :download_file do
    body { 'test' }
    association :download
  end
end
