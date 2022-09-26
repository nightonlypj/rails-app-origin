json.success true
json.infomations do
  json.array! @infomations do |infomation|
    json.id infomation.id
    json.partial! 'infomation', infomation: infomation, use_body: false

    json.force_started_at infomation.force_started_at.present? ? l(infomation.force_started_at, format: :json) : nil
    json.force_ended_at infomation.force_ended_at.present? ? l(infomation.force_ended_at, format: :json) : nil
  end
end
