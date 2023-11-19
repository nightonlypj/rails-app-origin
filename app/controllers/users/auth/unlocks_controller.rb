# frozen_string_literal: true

class Users::Auth::UnlocksController < DeviseTokenAuth::UnlocksController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  before_action :validate_redirect_url_param, only: %i[create show] # NOTE: 追加
  prepend_before_action :response_already_authenticated, only: :create, if: :user_signed_in?
  prepend_before_action :response_not_acceptable_for_not_api, only: :create
  prepend_before_action :response_not_acceptable_for_not_html, only: :show
  prepend_before_action :update_request_uid_header

  # POST /users/auth/unlock(.json) アカウントロック解除API[メール再送](処理)
  def create
    return render_create_error_missing_email if request.request_parameters.blank?
    return render_create_error_missing_redirect_url unless @redirect_url
    return render_error_not_allowed_redirect_url if blacklisted_redirect_url?(@redirect_url)

    @email = get_case_insensitive_field_from_resource_params(:email)
    @resource = find_resource(:email, @email)

    # NOTE: 未ロックの場合はエラーにする
    if @resource.present? && !@resource.access_locked?
      return render '/failure', locals: { alert: t('errors.messages.not_locked') }, status: :unprocessable_entity
    end

    if @resource
      yield @resource if block_given?

      @resource.send_unlock_instructions(
        email: @email,
        provider: 'email',
        redirect_url: @redirect_url, # NOTE: 追加
        client_config: params[:config_name]
      )

      if @resource.errors.empty?
        render_create_success
      else
        render_create_error @resource.errors
      end
    else
      render_not_found_error
    end
  end

  # GET /users/auth/unlock アカウントロック解除(処理)
  def show
    @resource = resource_class.unlock_access_by_token(params[:unlock_token])

    if @resource.persisted?
      # token = @resource.create_token # NOTE: 削除
      @resource.save!
      yield @resource if block_given?

      return redirect_to Settings.unlock_success_url_not, allow_other_host: true if @redirect_url.blank?
      return redirect_to Settings.unlock_success_url_bad, allow_other_host: true if blacklisted_redirect_url?(@redirect_url)

      # redirect_header_options = { unlock: true }
      redirect_header_options = { unlock: true, notice: t('devise.unlocks.unlocked') }
      # redirect_headers = build_redirect_headers(token.token, token.client, redirect_header_options)
      # redirect_to(@resource.build_auth_url(after_unlock_path_for(@resource), redirect_headers))
      redirect_to DeviseTokenAuth::Url.generate(@redirect_url, redirect_header_options), allow_other_host: true
    else
      render_show_error
    end
  end

  private

  def validate_redirect_url_param
    @redirect_url = params.fetch(:redirect_url, Settings.default_unlock_success_url)
    # return render_create_error_missing_redirect_url unless @redirect_url
    # return render_error_not_allowed_redirect_url if blacklisted_redirect_url?(@redirect_url)
  end

  def render_create_error_missing_redirect_url
    render '/failure', locals: { alert: t('devise_token_auth.unlocks.missing_redirect_url') }, status: :unprocessable_entity
  end

  def render_error_not_allowed_redirect_url
    render '/failure', locals: { alert: t('devise_token_auth.unlocks.not_allowed_redirect_url') }, status: :unprocessable_entity
  end

  def render_create_error_missing_email
    # render_error(401, I18n.t('devise_token_auth.unlocks.missing_email'))
    render '/failure', locals: { alert: t('errors.messages.validate_unlock_params') }, status: :bad_request
  end

  def render_create_success
    # render json: { success: true, message: success_message('unlocks', @email) }
    render '/users/auth/success', locals: { current_user: nil, notice: success_message('unlocks', @email) }
  end

  def render_create_error(errors)
    # render json: { success: false, errors: errors }, status: 400
    render '/failure', locals: { errors: }, status: :unprocessable_entity
  end

  def render_show_error
    # raise ActionController::RoutingError, 'Not Found'
    return redirect_to Settings.unlock_error_url_not, allow_other_host: true if @redirect_url.blank?
    return redirect_to Settings.unlock_error_url_bad, allow_other_host: true if blacklisted_redirect_url?(@redirect_url)

    alert = t("activerecord.errors.models.user.attributes.unlock_token.#{params[:unlock_token].blank? ? 'blank' : 'invalid'}")
    redirect_header_options = { unlock: false, alert: }
    redirect_to DeviseTokenAuth::Url.generate(@redirect_url, redirect_header_options), allow_other_host: true
  end

  def render_not_found_error
    if Devise.paranoid
      # :nocov:
      # render_error(404, I18n.t('devise_token_auth.unlocks.sended_paranoid'))
      render '/failure', locals: { alert: t('devise_token_auth.unlocks.sended_paranoid') }, status: :unprocessable_entity
      # :nocov:
    else
      # render_error(404, I18n.t('devise_token_auth.unlocks.user_not_found', email: @email))
      errors = { email: t('devise_token_auth.unlocks.user_not_found') }
      errors[:full_messages] = ["#{t('activerecord.attributes.user.email')} #{errors[:email]}"]
      render '/failure', locals: { errors:, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
    end
  end
end
