# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  prepend_before_action :authenticate_scope!, only: %i[edit update destroy delete]

  # GET /users/sign_up アカウント登録
  # def new
  #   super
  # end

  # POST /users アカウント登録(処理)
  # def create
  #   super
  # end

  # GET /users/edit 登録情報変更
  # def edit
  #   super
  # end

  # PUT /users 登録情報変更(処理)
  # def update
  #   super
  # end

  # GET /users/delete アカウント削除
  # def delete
  # end

  # DELETE /users アカウント削除(処理)
  def destroy
    resource.delete_reserved
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed_reserved
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /users/cancel
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
  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end
end
