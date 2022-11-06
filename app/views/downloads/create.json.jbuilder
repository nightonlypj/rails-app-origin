json.success true
json.alert alert if alert.present?
json.notice notice if notice.present?

json.download do
  json.partial! 'download', download: @download
end
