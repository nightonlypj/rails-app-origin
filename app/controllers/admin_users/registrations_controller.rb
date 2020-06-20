# frozen_string_literal: true

class AdminUsers::RegistrationsController < Devise::RegistrationsController
  layout 'admin_users'

  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /admin_users/sign_up アカウント登録
  # def new
  #   super
  # end

  # POST /admin_users アカウント登録(処理)
  # def create
  #   super
  # end

  # GET /admin_users/edit 登録情報変更
  # def edit
  #   super
  # end

  # PUT /admin_users 登録情報変更(処理)
  # def update
  #   super
  # end

  # DELETE /admin_users アカウント削除(処理)
  # def destroy
  #   super
  # end

  # GET /admin_users/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
