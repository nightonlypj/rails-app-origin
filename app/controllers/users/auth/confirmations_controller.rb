# frozen_string_literal: true

class Users::Auth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Devise::ConfirmationsConcern
  skip_before_action :verify_authenticity_token
  prepend_before_action :response_not_acceptable_for_not_api, only: :create
  prepend_before_action :response_not_acceptable_for_not_html, only: :show
  prepend_before_action :update_request_uid_header

  # POST /users/auth/confirmation(.json) メールアドレス確認API[メール再送](処理)
  def create
    return render '/failure', locals: { alert: t('errors.messages.validate_confirmation_params') }, status: :bad_request if request.request_parameters.blank?
    if params[:redirect_url].blank?
      return render '/failure', locals: { alert: t('devise_token_auth.confirmations.missing_confirm_success_url') }, status: :unprocessable_entity
    end
    if blacklisted_redirect_url?(params[:redirect_url])
      return render '/failure', locals: { alert: t('devise_token_auth.confirmations.redirect_url_not_allowed') }, status: :unprocessable_entity
    end

    # NOTE: 確認済み・不要の場合はエラーにする
    resource = params[:email].present? ? resource_class.find_by(email: params[:email]) : nil
    return render '/failure', locals: { alert: t('errors.messages.already_confirmed') }, status: :unprocessable_entity if already_confirmed?(resource)

    super
  end

  # GET /users/auth/confirmation メールアドレス確認(処理)
  def show
    @resource = resource_class.confirm_by_token(resource_params[:confirmation_token])
    if @resource.errors.empty?
      yield @resource if block_given?

      return redirect_to Settings.confirmation_success_url_not, allow_other_host: true if redirect_url.blank?
      return redirect_to Settings.confirmation_success_url_bad, allow_other_host: true if blacklisted_redirect_url?(redirect_url)

      # redirect_header_options = { account_confirmation_success: true }
      redirect_header_options = { account_confirmation_success: true, notice: t('devise.confirmations.confirmed') }
      # if signed_in?(resource_name)
      #   token = signed_in_resource.create_token
      #   signed_in_resource.save!
      #
      #   redirect_headers = build_redirect_headers(token.token, token.client, redirect_header_options)
      #   redirect_to signed_in_resource.build_auth_url(redirect_url, redirect_headers)
      # else
      # end
      # else
      # raise ActionController::RoutingError, 'Not Found'
    elsif already_confirmed?(@resource)
      return redirect_to Settings.confirmation_success_url_not, allow_other_host: true if redirect_url.blank?
      return redirect_to Settings.confirmation_success_url_bad, allow_other_host: true if blacklisted_redirect_url?(redirect_url)

      redirect_header_options = { account_confirmation_success: true, alert: t('errors.messages.already_confirmed') }
    else
      return redirect_to Settings.confirmation_error_url_not, allow_other_host: true if redirect_url.blank?
      return redirect_to Settings.confirmation_error_url_bad, allow_other_host: true if blacklisted_redirect_url?(redirect_url)

      redirect_header_options = { account_confirmation_success: false, alert: t('activerecord.errors.models.user.attributes.confirmation_token.invalid') }
    end
    redirect_to DeviseTokenAuth::Url.generate(redirect_url, redirect_header_options), allow_other_host: true
  end

  private

  # 確認済み・不要かを返却
  def already_confirmed?(resource)
    resource&.confirmed_at&.present? && (resource.confirmation_sent_at.blank? || resource.confirmed_at > resource.confirmation_sent_at)
  end

  protected

  # NOTE: 未使用
  # def render_create_error_missing_email
  #   # render_error(401, I18n.t('devise_token_auth.confirmations.missing_email'))
  #   render '/failure', locals: { alert: t('errors.messages.validate_confirmation_params') }, status: :bad_request
  # end

  def render_create_success
    # render json: { success: true, message: success_message('confirmations', @email) }
    render '/users/auth/success', locals: { current_user: nil, notice: success_message('confirmations', @email) }
  end

  def render_not_found_error
    if Devise.paranoid
      # :nocov:
      # render_error(404, I18n.t('devise_token_auth.confirmations.sended_paranoid'))
      render '/failure', locals: { alert: t('devise_token_auth.confirmations.sended_paranoid') }, status: :unprocessable_entity
      # :nocov:
    else
      # render_error(404, I18n.t('devise_token_auth.confirmations.user_not_found', email: @email))
      errors = { email: t('devise_token_auth.confirmations.user_not_found') }
      errors[:full_messages] = ["#{t('activerecord.attributes.user.email')} #{errors[:email]}"]
      render '/failure', locals: { errors:, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
    end
  end
end
