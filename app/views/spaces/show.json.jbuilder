json.success true
json.alert alert if alert.present?
json.notice notice if notice.present?

json.space do
  json.partial! 'space', space: @space
  json.member_count @member_count

  if @current_member.present?
    json.current_member do
      json.power @current_member.power
      json.power_i18n @current_member.power_i18n
    end

    if @current_member.power_admin?
      if @space.created_user.present?
        json.created_user do
          json.partial! './users/auth/user', user: @space.created_user, use_email: true
        end
      end
      if @space.last_updated_user.present?
        json.last_updated_user do
          json.partial! './users/auth/user', user: @space.last_updated_user, use_email: true
        end
      end
      json.created_at l(@space.created_at, format: :json)
      json.last_updated_at l(@space.last_updated_at, format: :json, default: nil)
    end
  end
end
