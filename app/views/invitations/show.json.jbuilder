json.success true
json.alert alert if alert.present?
json.notice notice if notice.present?

json.invitation do
  json.partial! 'invitation', invitation: @invitation
end
