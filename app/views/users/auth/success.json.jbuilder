json.success true
json.alert alert if alert.present?
json.notice notice if notice.present?

if current_user.present?
  json.user do
    json.partial! '/users/auth/current_user', use_email: false, use_add_info: true
  end
end
