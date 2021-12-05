# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: %i[create]

  # GET /users/sign_in ログイン
  # def new
  #   super
  # end

  # POST /users/sign_in ログイン(処理)
  # def create
  #   super
  # end

  # GET /users/sign_out ログアウト
  def delete
    redirect_to root_path, alert: t('devise.sessions.already_signed_out') unless user_signed_in?
  end

  # DELETE /users/sign_out ログアウト(処理)
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
