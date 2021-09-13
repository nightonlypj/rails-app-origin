# frozen_string_literal: true

class Users::Auth::TokenValidationsController < DeviseTokenAuth::TokenValidationsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :not_acceptable_response_not_api_accept

  # GET /users/auth/validate_token(.json) トークン検証API(処理)
  # def validate_token
  #   super
  # end
end
