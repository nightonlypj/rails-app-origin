json.success true
json.download do
  json.total_count @downloads.total_count
  json.current_page @downloads.current_page
  json.total_pages @downloads.total_pages
  json.limit_value @downloads.limit_value
end
json.downloads do
  json.array! @downloads do |download|
    json.partial! 'download', download: download
  end
end

json.undownloaded_count current_user.undownloaded_count
