# frozen_string_literal: true

class Users::Auth::SessionsController < DeviseTokenAuth::SessionsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :not_acceptable_response_not_api_accept

  # POST /users/auth/sign_in(.json) ログインAPI(処理)
  # def create
  #   super
  # end

  # DELETE /users/auth/sign_out(.json) ログアウトAPI(処理)
  # def destroy
  #   super
  # end
end
