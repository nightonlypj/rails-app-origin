json.space do
  json.total_count @spaces.total_count
  json.current_page @spaces.current_page
  json.total_pages @spaces.total_pages
  json.limit_value @spaces.limit_value
end
json.spaces do
  json.array! @spaces do |space|
    json.subdomain space.subdomain
    json.name space.name
    json.created_at l(space.created_at, format: :json)
    json.customer do
      json.code space.customer.code
      json.name space.customer.name
    end
  end
end
