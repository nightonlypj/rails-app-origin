json.success true
json.alert alert if alert.present?
json.notice notice if notice.present?

json.count @codes.count
json.destroy_count @members.count
json.include_myself @include_myself