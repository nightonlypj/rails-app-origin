json.success true
json.search_params do
  json.text @text
  json.exclude @exclude ? 1 : 0
end

json.space do
  json.total_count @spaces.total_count
  json.current_page @spaces.current_page
  json.total_pages @spaces.total_pages
  json.limit_value @spaces.limit_value
end
json.spaces do
  json.array! @spaces do |space|
    json.partial! 'space', space: space

    if @members[space.id].present?
      json.current_member do
        json.power @members[space.id].power
        json.power_i18n @members[space.id].power_i18n
      end
    end
  end
end
