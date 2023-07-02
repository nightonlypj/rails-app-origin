json.success true
json.search_params do
  json.text @text
  json.public @checked[:public] ? 1 : 0
  json.private @checked[:private] ? 1 : 0
  json.join @checked[:join] ? 1 : 0
  json.nojoin @checked[:nojoin] ? 1 : 0
  json.active @checked[:active] ? 1 : 0
  json.destroy @checked[:destroy] ? 1 : 0
end

json.space do
  json.total_count @spaces.total_count
  json.current_page @spaces.current_page
  json.total_pages @spaces.total_pages
  json.limit_value @spaces.limit_value
end
json.spaces do
  json.array! @spaces do |space|
    json.partial!('space', space:)

    if @members[space.id].present?
      json.current_member do
        member = @members[space.id]
        json.power member.power
        json.power_i18n member.power_i18n
      end
    end
  end
end
