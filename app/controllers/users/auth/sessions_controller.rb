# frozen_string_literal: true

class Users::Auth::SessionsController < DeviseTokenAuth::SessionsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :unauthenticated_response_sign_out, only: %i[destroy], unless: :user_signed_in?
  prepend_before_action :not_acceptable_response_not_api_accept

  # POST /users/auth/sign_in(.json) ログインAPI(処理)
  def create
    return render './failure', locals: { alert: t('devise_token_auth.sessions.bad_credentials') }, status: :bad_request if request.request_parameters.blank?
    return render_create_error_bad_credentials if params[:email].blank? || params[:password].blank?

    super
  end

  # DELETE /users/auth/sign_out(.json) ログアウトAPI(処理)
  def destroy
    return render './failure', locals: { alert: t('devise.sessions.already_signed_out') }, status: :unauthorized unless user_signed_in?

    super
  end

  private

  def unauthenticated_response_sign_out
    render './failure', locals: { alert: t('devise_token_auth.sessions.user_not_found') }, status: :unauthorized
  end

  protected

  # Tips: 未使用
  # def render_new_error
  #   # render_error(405, I18n.t('devise_token_auth.sessions.not_supported'))
  #   render './failure', locals: { alert: t('devise_token_auth.registrations.user_not_found') }, status: :not_found
  # end

  def render_create_success
    # render json: { data: resource_data(resource_json: @resource.token_validation_response) }
    render './users/auth/success', locals: { notice: t('devise.sessions.signed_in') }
  end

  def render_create_error_not_confirmed
    # render_error(401, I18n.t('devise_token_auth.sessions.not_confirmed', email: @resource.email))
    render './failure', locals: { alert: t('devise.failure.unconfirmed') }, status: :unprocessable_entity
  end

  def render_create_error_account_locked
    # render_error(401, I18n.t('devise.mailer.unlock_instructions.account_lock_msg'))
    render './failure', locals: { alert: t('devise.failure.locked') }, status: :unprocessable_entity
  end

  def render_create_error_bad_credentials
    # render_error(401, I18n.t('devise_token_auth.sessions.bad_credentials'))
    render './failure', locals: { alert: t('devise.failure.invalid') }, status: :unprocessable_entity
  end

  def render_destroy_success
    # render json: { success:true }, status: 200
    render './users/auth/success', locals: { notice: t('devise.sessions.signed_out') }
  end

  # Tips: 未使用
  # def render_destroy_error
  #   # render_error(404, I18n.t('devise_token_auth.sessions.user_not_found'))
  #   render './failure', locals: { alert: t('devise_token_auth.sessions.user_not_found') }, status: :unprocessable_entity
  # end
end
