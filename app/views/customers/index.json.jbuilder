json.total_count @customers.total_count
json.current_page @customers.current_page
json.total_pages @customers.total_pages
json.limit_value @customers.limit_value
json.customers do
  json.array! @customers do |customer|
    json.name customer.name
    json.current_user do
      json.array! customer.customer_user do |customer_user|
        json.power customer_user.power
      end
    end
  end
end
