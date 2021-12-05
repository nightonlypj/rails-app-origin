json.success true
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
    json.force_started_at infomation.force_started_at.present? ? l(infomation.force_started_at, format: :json) : nil
    json.force_ended_at infomation.force_ended_at.present? ? l(infomation.force_ended_at, format: :json) : nil
    json.target infomation.target
  end
end
