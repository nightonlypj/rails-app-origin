json.user do
  json.partial! 'users/auth/user', user: member.user, use_email: current_member.power_admin?
end
json.power member.power
json.power_i18n member.power_i18n

if member.invitation_user.present? && current_member.power_admin?
  json.invitation_user do
    json.partial! 'users/auth/user', user: member.invitation_user, use_email: true
  end
end
json.invitationed_at l(member.invitationed_at, format: :json, default: nil)
