# frozen_string_literal: true

class Users::Auth::TokenValidationsController < DeviseTokenAuth::TokenValidationsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :not_acceptable_response_not_api_accept
  prepend_before_action :update_request_uid_header

  # GET /users/auth/validate_token(.json) トークン検証API(処理)
  # def validate_token
  #   super
  # end

  protected

  def render_validate_token_success
    # render json: { success: true, data: resource_data(resource_json: @resource.token_validation_response) }
    render './users/auth/success'
  end

  def render_validate_token_error
    # render_error(401, I18n.t('devise_token_auth.token_validations.invalid'))
    render './failure', locals: { alert: t('devise_token_auth.token_validations.invalid') }, status: :unauthorized
  end
end
