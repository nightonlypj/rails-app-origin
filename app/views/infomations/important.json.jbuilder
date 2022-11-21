json.success true
json.infomations do
  json.array! @infomations do |infomation|
    json.id infomation.id
    json.partial! 'infomation', infomation: infomation, use_body: false

    json.force_started_at l(infomation.force_started_at, format: :json, default: nil)
    json.force_ended_at l(infomation.force_ended_at, format: :json, default: nil)
  end
end
