json.success true
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
  json.email current_user.email
  ## Trackable
  json.sign_in_count current_user.sign_in_count
  json.current_sign_in_at current_user.current_sign_in_at.present? ? l(current_user.current_sign_in_at, format: :json) : nil
  json.last_sign_in_at current_user.last_sign_in_at.present? ? l(current_user.last_sign_in_at, format: :json) : nil
  json.current_sign_in_ip current_user.current_sign_in_ip
  json.last_sign_in_ip current_user.last_sign_in_ip
  ## Confirmable
  json.unconfirmed_email user_valid_confirmation_token? ? current_user.unconfirmed_email : nil
  ## 削除予約
  json.destroy_schedule_days Settings['destroy_schedule_days']
  json.destroy_requested_at current_user.destroy_requested_at.present? ? l(current_user.destroy_requested_at, format: :json) : nil
  json.destroy_schedule_at current_user.destroy_schedule_at.present? ? l(current_user.destroy_schedule_at, format: :json) : nil
  ## 作成日時
  json.created_at current_user.created_at.present? ? l(current_user.created_at, format: :json) : nil
end
