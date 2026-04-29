# frozen_string_literal: true

class AdminUsers::PasswordsController < Devise::PasswordsController
  include Devise::PasswordsConcern

  layout 'admin_users'

  # パスワード再設定[メール送信]
  # def new
  #   super
  # end

  # パスワード再設定[メール送信](処理)
  # def create
  #   super
  # end

  # パスワード再設定
  def edit
    unless valid_reset_password_token?(params[:reset_password_token])
      return redirect_to new_admin_user_password_path, alert: t('activerecord.errors.models.admin_user.attributes.reset_password_token.invalid')
    end

    super
  end

  # パスワード再設定(処理)
  def update
    unless valid_reset_password_token?(resource_params[:reset_password_token])
      return redirect_to new_admin_user_password_path, alert: t('activerecord.errors.models.admin_user.attributes.reset_password_token.invalid')
    end

    params[:admin_user][:password_confirmation] = '' if params[:admin_user][:password_confirmation].nil? # NOTE: nilだとチェックされずに保存される為
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
end
