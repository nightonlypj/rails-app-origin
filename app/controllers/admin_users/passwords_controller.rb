# frozen_string_literal: true

class AdminUsers::PasswordsController < Devise::PasswordsController
  # GET /admin_users/password/new パスワードをお忘れですか？
  # def new
  #   super
  # end

  # POST /admin_users/password パスワードをお忘れですか？(処理)
  # def create
  #   super
  # end

  # GET /admin_users/password/edit パスワード再設定
  # def edit
  #   super
  # end

  # PUT /admin_users/password パスワード再設定(処理)
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
