json.success true
json.space do
  json.partial! '/spaces/space', space: @space

  json.current_member do
    json.power @current_member.power
    json.power_i18n @current_member.power_i18n
  end
end

json.invitation do
  json.total_count @invitations.total_count
  json.current_page @invitations.current_page
  json.total_pages @invitations.total_pages
  json.limit_value @invitations.limit_value
end
json.invitations do
  json.array! @invitations do |invitation|
    json.partial! 'invitation', invitation:
  end
end
