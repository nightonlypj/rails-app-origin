# frozen_string_literal: true

class Users::Auth::PasswordsController < DeviseTokenAuth::PasswordsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :not_acceptable_response_not_api_accept, only: %i[create update]
  prepend_before_action :not_acceptable_response_not_html_accept, only: %i[edit]

  # POST /users/auth/password(.json) パスワード再設定API[メール送信](処理)
  # def create
  #   super
  # end

  # GET /users/auth/password パスワード再設定
  # def edit
  #   super
  # end

  # PUT(PATCH) /users/auth/password/update(.json) パスワード再設定API(処理)
  # def update
  #   super
  # end
end
