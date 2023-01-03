json.success @invitation.present?
json.invitation do
  if @invitation.email.present?
    json.email @invitation.email
  else
    json.domains @invitation.domains_array
  end
end
