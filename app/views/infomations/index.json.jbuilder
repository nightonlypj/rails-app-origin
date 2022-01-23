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
    json.label infomation.label
    json.label_i18n infomation.label_i18n
    json.title infomation.title
    json.summary infomation.summary
    json.body_present infomation.body.present?
    json.started_at l(infomation.started_at, format: :json)
    json.ended_at infomation.ended_at.present? ? l(infomation.ended_at, format: :json) : nil
    json.target infomation.target
  end
end
