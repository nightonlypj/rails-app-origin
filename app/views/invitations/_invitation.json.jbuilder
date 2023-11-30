json.status invitation.status
json.status_i18n invitation.status_i18n

json.code invitation.code
if invitation.email.present?
  json.email invitation.email
else
  json.domains invitation.domains_array
end
json.power invitation.power
json.power_i18n invitation.power_i18n
json.memo invitation.memo

json.ended_at l(invitation.ended_at, format: :json, default: nil)
json.destroy_requested_at l(invitation.destroy_requested_at, format: :json, default: nil)
json.destroy_schedule_at l(invitation.destroy_schedule_at, format: :json, default: nil)
json.email_joined_at l(invitation.email_joined_at, format: :json, default: nil) if invitation.email.present?

if invitation.created_user_id.present?
  json.created_user do
    json.partial! '/users/auth/user', user: invitation.created_user, use_email: true if invitation.created_user.present?
    json.deleted invitation.created_user.blank?
  end
end
json.created_at l(invitation.created_at, format: :json)

if invitation.last_updated_user_id.present?
  json.last_updated_user do
    json.partial! '/users/auth/user', user: invitation.last_updated_user, use_email: true if invitation.last_updated_user.present?
    json.deleted invitation.last_updated_user.blank?
  end
end
json.last_updated_at l(invitation.last_updated_at, format: :json, default: nil)
