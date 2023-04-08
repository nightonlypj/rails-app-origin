# frozen_string_literal: true

class AdminUsers::SessionsController < Devise::SessionsController
  layout 'admin_users'

  # before_action :configure_sign_in_params, only: :create

  # GET /admin/sign_in ログイン
  # def new
  #   super
  # end

  # POST /admin/sign_in ログイン(処理)
  # def create
  #   super
  # end

  # POST(GET,DELETE) /admin/sign_out ログアウト(処理)
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
