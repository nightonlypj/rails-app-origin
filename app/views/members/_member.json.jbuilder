json.user do
  json.partial! '/users/auth/user', user: member.user, use_email: current_member.power_admin?
end
json.power member.power
json.power_i18n member.power_i18n

if current_member.power_admin? && member.invitationed_user_id.present?
  json.invitationed_user do
    json.partial! '/users/auth/user', user: member.invitationed_user, use_email: true if member.invitationed_user.present?
    json.deleted member.invitationed_user.blank?
  end
end
json.invitationed_at l(member.invitationed_at, format: :json, default: nil)

if current_member.power_admin? && member.last_updated_user_id.present?
  json.last_updated_user do
    json.partial! '/users/auth/user', user: member.last_updated_user, use_email: true if member.last_updated_user.present?
    json.deleted member.last_updated_user.blank?
  end
end
json.last_updated_at l(member.last_updated_at, format: :json, default: nil) if current_member.power_admin?
