json.success true
json.user do
  json.partial! 'users/auth/current_user', use_email: true

  ## Trackable
  json.sign_in_count current_user.sign_in_count
  json.current_sign_in_at current_user.current_sign_in_at.present? ? l(current_user.current_sign_in_at, format: :json) : nil
  json.last_sign_in_at current_user.last_sign_in_at.present? ? l(current_user.last_sign_in_at, format: :json) : nil
  json.current_sign_in_ip current_user.current_sign_in_ip
  json.last_sign_in_ip current_user.last_sign_in_ip
  ## Confirmable
  json.unconfirmed_email user_valid_confirmation_token? ? current_user.unconfirmed_email : nil
  ## 作成日時
  json.created_at current_user.created_at.present? ? l(current_user.created_at, format: :json) : nil
end
