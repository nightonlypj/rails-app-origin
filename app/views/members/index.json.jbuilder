json.success true
json.search_params do
  json.text @text
  json.power @powers.join(',')
  json.sort @sort
  json.desc @desc ? 1 : 0
end

json.space do
  json.partial! './spaces/space', space: @space

  json.current_member do
    json.power @current_member.power
    json.power_i18n @current_member.power_i18n
  end
end

json.member do
  json.total_count @members.total_count
  json.current_page @members.current_page
  json.total_pages @members.total_pages
  json.limit_value @members.limit_value
end
json.members do
  json.array! @members do |member|
    json.partial! 'member', member:, current_member: @current_member
  end
end
