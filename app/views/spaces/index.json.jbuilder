json.total_count @spaces.total_count
json.current_page @spaces.current_page
json.total_pages @spaces.total_pages
json.limit_value @spaces.limit_value
json.spaces do
  json.array! @spaces, :subdomain, :name, :created_at, :updated_at
end
