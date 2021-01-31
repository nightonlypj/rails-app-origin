# frozen_string_literal: true

class AdminUsers::PasswordsController < Devise::PasswordsController
  layout 'admin_users'

  # GET /admin_users/password/new パスワード再設定[メール送信]
  # def new
  #   super
  # end

  # POST /admin_users/password パスワード再設定[メール送信](処理)
  # def create
  #   super
  # end

  # GET /admin_users/password/edit パスワード再設定
  def edit
    return redirect_to new_admin_user_password_path, alert: invalid_token_message unless valid_reset_password_token?(params[:reset_password_token])

    super
  end

  # PUT /admin_users/password パスワード再設定(処理)
  def update
    return redirect_to new_admin_user_password_path, alert: invalid_token_message unless valid_reset_password_token?(resource_params[:reset_password_token])

    super
  end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  private

  # トークンエラーメッセージを返却
  def invalid_token_message
    t('activerecord.errors.models.admin_user.attributes.reset_password_token.invalid')
  end
end
