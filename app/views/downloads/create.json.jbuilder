json.success true
json.notice notice if notice.present?

json.download do
  json.partial! 'download', download: @download
end
