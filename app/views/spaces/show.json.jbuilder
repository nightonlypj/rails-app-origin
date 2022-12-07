json.success true
json.space do
  json.partial! 'space', space: @space
  json.member_count @member_count

  if @current_member.present?
    json.current_member do
      json.power @current_member.power
      json.power_i18n @current_member.power_i18n
    end
  end
end
