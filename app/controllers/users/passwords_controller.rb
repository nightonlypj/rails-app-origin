# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /users/password/new パスワード再設定メール送信
  # def new
  #   super
  # end

  # POST /users/password パスワード再設定メール送信(処理)
  # def create
  #   super
  # end

  # GET /users/password/edit パスワード再設定
  # def edit
  #   super
  # end

  # PUT /users/password パスワード再設定(処理)
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
