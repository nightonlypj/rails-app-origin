json.extract! customer_user, :id, :customer_id, :user_id, :power, :created_at, :updated_at
json.url customer_user_url(customer_user, format: :json)
