json.partial! './users/auth/user', user: current_user, use_email: use_email
json.provider current_user.provider

return unless use_add_info

## アカウント削除の猶予期間
json.destroy_schedule_days Settings.user_destroy_schedule_days

## お知らせ
json.infomation_unread_count current_user.infomation_unread_count
