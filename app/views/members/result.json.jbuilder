json.success true
json.notice notice

json.email do
  json.count @emails.count
  json.create_count @create_user_mails.count
  json.exist_count @exist_user_mails.count
  json.notfound_count @emails.count - @create_user_mails.count - @exist_user_mails.count
end
json.emails do
  json.array! @emails do |email|
    json.email email
    if @create_user_mails.include?(email)
      json.result 'create'
      json.result_i18n t('招待しました。')
    elsif @exist_user_mails.include?(email)
      json.result 'exist'
      json.result_i18n t('既に参加しています。')
    else
      json.result 'notfound'
      json.result_i18n t('アカウントが存在しません。登録後に招待してください。')
    end
  end
end
json.power @member.power
json.power_i18n @member.power_i18n

json.user_codes @user_codes
