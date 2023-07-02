json.success true
json.search_params do
  json.id @id
  json.target_id @target_id
end

json.download do
  json.total_count @downloads.total_count
  json.current_page @downloads.current_page
  json.total_pages @downloads.total_pages
  json.limit_value @downloads.limit_value
end
json.downloads do
  json.array! @downloads do |download|
    json.partial! 'download', download:
  end
end

if @download.present?
  json.target do
    json.status @download.status
    json.alert @alert if @alert.present?
    json.notice @notice if @notice.present?
  end
end
json.undownloaded_count current_user.undownloaded_count
