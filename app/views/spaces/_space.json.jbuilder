json.code space.code
json.upload_image space.image?
json.image_url do
  json.mini "#{Settings.base_image_url}#{space.image_url(:mini)}"
  json.small "#{Settings.base_image_url}#{space.image_url(:small)}"
  json.medium "#{Settings.base_image_url}#{space.image_url(:medium)}"
  json.large "#{Settings.base_image_url}#{space.image_url(:large)}"
  json.xlarge "#{Settings.base_image_url}#{space.image_url(:xlarge)}"
end
json.name space.name
json.description space.description
json.private space.private

## 削除予約
json.destroy_requested_at l(space.destroy_requested_at, format: :json, default: nil)
json.destroy_schedule_at l(space.destroy_schedule_at, format: :json, default: nil)
