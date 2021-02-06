json.customer do
  json.total_count @customers.total_count
  json.current_page @customers.current_page
  json.total_pages @customers.total_pages
  json.limit_value @customers.limit_value
end
json.customers do
  json.array! @customers do |customer|
    json.code customer.code
    json.name customer.name
    json.created_at l(customer.created_at, format: :json)
    json.current_user do
      json.power customer.member.first.power
    end
  end
end
