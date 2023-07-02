json.success true
json.search_params do
  json.start_date l(@start_date, format: :json)
  json.end_date l(@end_date, format: :json)
end

json.holidays do
  json.array! @holidays do |holiday|
    json.date l(holiday.date, format: :json)
    json.name holiday.name
  end
end
