json.success true
json.infomation do
  json.total_count @infomations.total_count
  json.current_page @infomations.current_page
  json.total_pages @infomations.total_pages
  json.limit_value @infomations.limit_value
end
json.infomations do
  json.array! @infomations do |infomation|
    json.id infomation.id
    json.title infomation.title
    json.summary infomation.summary.present? ? infomation.summary : ''
    json.started_at l(infomation.started_at, format: :json)
    json.ended_at infomation.ended_at.present? ? l(infomation.ended_at, format: :json) : ''
    json.target infomation.target
  end
end
