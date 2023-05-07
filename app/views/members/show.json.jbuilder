json.success true
json.notice notice if notice.present?

json.member do
  json.partial! 'member', member: @member, current_member: @current_member
end
