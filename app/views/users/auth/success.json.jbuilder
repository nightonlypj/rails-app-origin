json.success true
if current_user.present?
  json.user do
    json.provider current_user.provider
    json.code current_user.code
    json.image_url do
      json.mini "#{Settings['base_image_url']}#{current_user.image_url(:mini)}"
      json.small "#{Settings['base_image_url']}#{current_user.image_url(:small)}"
      json.medium "#{Settings['base_image_url']}#{current_user.image_url(:medium)}"
      json.large "#{Settings['base_image_url']}#{current_user.image_url(:large)}"
      json.xlarge "#{Settings['base_image_url']}#{current_user.image_url(:xlarge)}"
    end
    json.name current_user.name
    json.email current_user.email
    ## Trackable
    json.sign_in_count current_user.sign_in_count
    json.current_sign_in_at current_user.current_sign_in_at.present? ? l(current_user.current_sign_in_at, format: :json) : nil
    json.last_sign_in_at current_user.last_sign_in_at.present? ? l(current_user.last_sign_in_at, format: :json) : nil
    json.current_sign_in_ip current_user.current_sign_in_ip
    json.last_sign_in_ip current_user.last_sign_in_ip
    ## Confirmable
    json.confirmed_at current_user.confirmed_at.present? ? l(current_user.confirmed_at, format: :json) : nil
    json.confirmation_sent_at current_user.confirmation_sent_at.present? ? l(current_user.confirmation_sent_at, format: :json) : nil
    json.unconfirmed_email current_user.unconfirmed_email
    ## 削除予約
    json.destroy_requested_at current_user.destroy_requested_at.present? ? l(current_user.destroy_requested_at, format: :json) : nil
    json.destroy_schedule_at current_user.destroy_schedule_at.present? ? l(current_user.destroy_schedule_at, format: :json) : nil
  end
end
json.alert alert if alert.present?
json.notice notice if notice.present?
