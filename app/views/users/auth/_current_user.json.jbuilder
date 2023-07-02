json.partial!('./users/auth/user', user: current_user, use_email:)
json.provider current_user.provider

return unless use_add_info

## アカウント削除の猶予期間
json.destroy_schedule_days Settings.user_destroy_schedule_days

## お知らせ
json.infomation_unread_count current_user.infomation_unread_count
## ダウンロード結果
json.undownloaded_count current_user.undownloaded_count

## 参加スペース
spaces = current_user.spaces.active
members = Member.where(space_id: spaces.ids, user: current_user).index_by(&:space_id)
json.spaces do
  json.array! spaces do |space|
    json.partial!('./spaces/space', space:)

    json.current_member do
      member = members[space.id]
      json.power member.power
      json.power_i18n member.power_i18n
    end
  end
end
