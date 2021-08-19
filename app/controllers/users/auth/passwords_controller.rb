# frozen_string_literal: true

class Users::Auth::PasswordsController < DeviseTokenAuth::PasswordsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token

  # POST /users/auth/password パスワード再設定[メール送信](処理)
  # def create
  #   super
  # end

  # GET /users/auth/password パスワード再設定
  # def edit
  #   super
  # end

  # PUT(PATCH) /users/auth/password/update パスワード再設定(処理)
  # def update
  #   super
  # end
end
