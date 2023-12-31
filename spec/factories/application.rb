FactoryBot.define do
  trait :skip_validate do
    to_create { |instance| instance.save(validate: false) }
  end
end
