# frozen_string_literal: true

class Users::Auth::TokenValidationsController < DeviseTokenAuth::TokenValidationsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token

  # GET /users/auth/validate_token トークン検証(処理)
  # def validate_token
  #   super
  # end
end
