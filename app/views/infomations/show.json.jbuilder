json.success true
json.infomation do
  json.label @infomation.label
  json.label_i18n @infomation.label_i18n
  json.title @infomation.title
  json.summary @infomation.summary
  json.body @infomation.body
  json.started_at l(@infomation.started_at, format: :json)
  json.ended_at @infomation.ended_at.present? ? l(@infomation.ended_at, format: :json) : nil
  json.target @infomation.target
end
