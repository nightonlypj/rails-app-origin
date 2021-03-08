json.customer do
  json.code @customer.code
  json.name @customer.name
  json.created_at l(@customer.created_at, format: :json)
  json.current_user do
    json.power @customer.member.first.power
  end
  json.member do
    json.count @customer.member.count
  end
  json.space do
    json.count @customer.space.count
  end
end
