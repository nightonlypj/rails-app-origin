json.success true
if current_user.present?
  json.user do
    json.provider current_user.provider
    json.code current_user.code
    json.upload_image current_user.image?
    json.image_url do
      json.mini "#{Settings['base_image_url']}#{current_user.image_url(:mini)}"
      json.small "#{Settings['base_image_url']}#{current_user.image_url(:small)}"
      json.medium "#{Settings['base_image_url']}#{current_user.image_url(:medium)}"
      json.large "#{Settings['base_image_url']}#{current_user.image_url(:large)}"
      json.xlarge "#{Settings['base_image_url']}#{current_user.image_url(:xlarge)}"
    end
    json.name current_user.name
    ## 削除予約
    json.destroy_schedule_days Settings['destroy_schedule_days']
    json.destroy_requested_at current_user.destroy_requested_at.present? ? l(current_user.destroy_requested_at, format: :json) : nil
    json.destroy_schedule_at current_user.destroy_schedule_at.present? ? l(current_user.destroy_schedule_at, format: :json) : nil
    ## お知らせ
    json.infomation_unread_count current_user.infomation_unread_count
  end
end
json.alert alert if alert.present?
json.notice notice if notice.present?
