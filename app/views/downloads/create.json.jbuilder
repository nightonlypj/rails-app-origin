json.success true
json.notice notice

json.download do
  json.partial! 'download', download: @download
end
