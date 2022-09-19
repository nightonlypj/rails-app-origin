json.success true
if current_user.present?
  json.user do
    json.partial! 'users/auth/current_user', use_email: false
  end
end
json.alert alert if alert.present?
json.notice notice if notice.present?
