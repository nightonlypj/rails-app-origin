json.success true
json.space do
  json.total_count @spaces.total_count
  json.current_page @spaces.current_page
  json.total_pages @spaces.total_pages
  json.limit_value @spaces.limit_value
end
json.spaces do
  json.array! @spaces do |space|
    json.code space.code
    json.image_url do
      json.mini "#{Settings['base_image_url']}#{space.image_url(:mini)}"
      json.small "#{Settings['base_image_url']}#{space.image_url(:small)}"
      json.medium "#{Settings['base_image_url']}#{space.image_url(:medium)}"
      json.large "#{Settings['base_image_url']}#{space.image_url(:large)}"
      json.xlarge "#{Settings['base_image_url']}#{space.image_url(:xlarge)}"
    end
    json.name space.name
    json.description space.description
    json.private space.private
    json.destroy_requested_at space.destroy_requested_at.present? ? l(space.destroy_requested_at, format: :json) : nil
    json.destroy_schedule_at space.destroy_schedule_at.present? ? l(space.destroy_schedule_at, format: :json) : nil

    if @members[space.id].present?
      json.member do
        json.power @members[space.id].power
        json.power_i18n @members[space.id].power_i18n
      end
    end
  end
end
