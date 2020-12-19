json.customer do
  json.name @customer.name
end
json.customer_user do
  json.total_count @customer_users.total_count
  json.current_page @customer_users.current_page
  json.total_pages @customer_users.total_pages
  json.limit_value @customer_users.limit_value
end
json.customer_users do
  json.array! @customer_users do |customer_user|
    json.image_url "https://#{Settings['base_domain']}#{customer_user.user.image_url(:small)}"
    json.name customer_user.user.name
    json.email customer_user.user.email
    json.power customer_user.power
    json.invitationed_at customer_user.invitationed_at.present? ? l(customer_user.invitationed_at, format: :json) : nil
    json.registrationed_at customer_user.registrationed_at.present? ? l(customer_user.registrationed_at, format: :json) : nil
  end
end
