json.success true
json.space do
  json.code @space.code
  json.image_url do
    json.mini "#{Settings['base_image_url']}#{@space.image_url(:mini)}"
    json.small "#{Settings['base_image_url']}#{@space.image_url(:small)}"
    json.medium "#{Settings['base_image_url']}#{@space.image_url(:medium)}"
    json.large "#{Settings['base_image_url']}#{@space.image_url(:large)}"
    json.xlarge "#{Settings['base_image_url']}#{@space.image_url(:xlarge)}"
  end
  json.name @space.name
  json.description @space.description
  json.private @space.private
  json.destroy_requested_at @space.destroy_requested_at.present? ? l(@space.destroy_requested_at, format: :json) : nil
  json.destroy_schedule_at @space.destroy_schedule_at.present? ? l(@space.destroy_schedule_at, format: :json) : nil

  if @current_member.present?
    json.current_member do
      json.power @current_member.power
      json.power_i18n @current_member.power_i18n
    end
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
    json.user do
      json.code member.user.code
      json.image_url do
        json.mini "#{Settings['base_image_url']}#{member.user.image_url(:mini)}"
        json.small "#{Settings['base_image_url']}#{member.user.image_url(:small)}"
        json.medium "#{Settings['base_image_url']}#{member.user.image_url(:medium)}"
        json.large "#{Settings['base_image_url']}#{member.user.image_url(:large)}"
        json.xlarge "#{Settings['base_image_url']}#{member.user.image_url(:xlarge)}"
      end
      json.name member.user.name
      json.email member.user.email if @current_member.power_admin? # 管理者のみ
    end
    json.power member.power
    json.power_i18n member.power_i18n

    if member.invitation_user.present? && @current_member.power_admin? # 管理者のみ
      json.invitation_user do
        json.image_url do
          json.mini "#{Settings['base_image_url']}#{member.invitation_user.image_url(:mini)}"
          json.small "#{Settings['base_image_url']}#{member.invitation_user.image_url(:small)}"
          json.medium "#{Settings['base_image_url']}#{member.invitation_user.image_url(:medium)}"
          json.large "#{Settings['base_image_url']}#{member.invitation_user.image_url(:large)}"
          json.xlarge "#{Settings['base_image_url']}#{member.invitation_user.image_url(:xlarge)}"
        end
        json.name member.invitation_user.name
        json.email member.invitation_user.email
      end
    end
    json.invitationed_at member.invitationed_at.present? ? l(member.invitationed_at, format: :json) : nil
  end
end
