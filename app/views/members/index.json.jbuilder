json.customer do
  json.name @customer.name
end
json.member do
  json.total_count @members.total_count
  json.current_page @members.current_page
  json.total_pages @members.total_pages
  json.limit_value @members.limit_value
end
json.members do
  json.array! @members do |member|
    json.code member.user.code
    json.image_url "https://#{Settings['base_domain']}#{member.user.image_url(:small)}"
    json.name member.user.name
    json.email member.user.email
    json.power member.power
    json.invitationed_at member.invitationed_at.present? ? l(member.invitationed_at, format: :json) : nil
    json.registrationed_at member.registrationed_at.present? ? l(member.registrationed_at, format: :json) : nil
  end
end
