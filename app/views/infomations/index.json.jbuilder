json.success true
json.infomation do
  json.total_count @infomations.total_count
  json.current_page @infomations.current_page
  json.total_pages @infomations.total_pages
  json.limit_value @infomations.limit_value
end
json.infomations do
  json.array! @infomations do |infomation|
    json.partial! 'infomation', infomation: infomation, use_id: true, use_body: false
  end
end
