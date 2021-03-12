json.public_space do
  json.total_count @spaces.total_count
  json.current_page @spaces.current_page
  json.total_pages @spaces.total_pages
  json.limit_value @spaces.limit_value
end
json.public_spaces do
  json.array! @spaces do |space|
    json.subdomain space.subdomain
    json.image_url "https://#{Settings['base_domain']}#{space.image_url(:small)}"
    json.name space.name
    json.purpose space.purpose
    json.created_at l(space.created_at, format: :json)
  end
end
