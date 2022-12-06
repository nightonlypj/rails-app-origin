json.partial! './users/auth/user', user: current_user, use_email: use_email

json.provider current_user.provider
json.upload_image current_user.image?

## 削除予約
json.destroy_schedule_days Settings['destroy_schedule_days']
json.destroy_requested_at l(current_user.destroy_requested_at, format: :json, default: nil)
json.destroy_schedule_at l(current_user.destroy_schedule_at, format: :json, default: nil)

return unless use_add_info

## お知らせ
json.infomation_unread_count current_user.infomation_unread_count
