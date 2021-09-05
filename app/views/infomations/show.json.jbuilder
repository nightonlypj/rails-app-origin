json.success true
json.infomation do
  json.title @infomation.title
  json.body @infomation.body.present? ? @infomation.body : ''
  json.started_at l(@infomation.started_at, format: :json)
  json.ended_at @infomation.ended_at.present? ? l(@infomation.ended_at, format: :json) : ''
  json.target @infomation.target
end
