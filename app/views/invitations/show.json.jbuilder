json.success true
json.alert alert if alert.present?
json.notice notice if notice.present?

json.invitation do
  json.partial! 'invitation', invitation: @invitation

  ## 招待削除の猶予期間
  json.destroy_schedule_days Settings.invitation_destroy_schedule_days
end
