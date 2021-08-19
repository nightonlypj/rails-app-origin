# frozen_string_literal: true

class Users::Auth::SessionsController < DeviseTokenAuth::SessionsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token

  # POST /users/auth/sign_in ログイン(処理)
  # def create
  #   super
  # end

  # DELETE /users/auth/sign_out ログアウト(処理)
  # def destroy
  #   super
  # end
end
