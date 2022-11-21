json.success true
json.alert alert if alert.present?
json.notice notice if notice.present?

json.email do
  json.count @emails.count
  json.create_count @create_users.count
  json.exist_count @exist_users.count
  json.notfound_count @emails.count - @create_users.count - @exist_users.count
end
json.emails do
  json.array! @emails do |email|
    json.email email
    if @create_user_mails.include?(email)
      json.result 'create'
      json.result_i18n '招待しました。'
    elsif @exist_user_mails.include?(email)
      json.result 'exist'
      json.result_i18n '既に参加しています。'
    else
      json.result 'notfound'
      json.result_i18n 'アカウントが存在しません。登録後に招待してください。'
    end
  end
end
json.power @member.power
json.power_i18n @member.power_i18n

json.user_codes @user_codes
