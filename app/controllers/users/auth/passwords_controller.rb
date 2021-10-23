# frozen_string_literal: true

class Users::Auth::PasswordsController < DeviseTokenAuth::PasswordsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :already_authenticated_response, only: %i[create update], if: :user_signed_in?
  prepend_before_action :not_acceptable_response_not_api_accept, only: %i[create update]
  prepend_before_action :not_acceptable_response_not_html_accept, only: %i[edit]
  prepend_before_action :update_request_uid_header
  skip_after_action :update_auth_header, only: [:update]

  # POST /users/auth/password(.json) パスワード再設定API[メール送信](処理)
  def create
    return render_create_error_missing_email if request.request_parameters.blank?
    return render_create_error_missing_redirect_url unless @redirect_url
    return render_error_not_allowed_redirect_url if blacklisted_redirect_url?(@redirect_url)

    super
  end

  # GET /users/auth/password パスワード再設定
  def edit
    return redirect_to Settings['reset_password_error_url_not'] if @redirect_url.blank?
    return redirect_to Settings['reset_password_error_url_bad'] if blacklisted_redirect_url?(@redirect_url)

    super
  end

  # PUT(PATCH) /users/auth/password/update(.json) パスワード再設定API(処理)
  def update
    return render_create_error_missing_email if request.request_parameters.blank?

    resource = user_reset_password_token(params[:reset_password_token])
    # Tips: 存在しないトークンか、期限切れの場合はエラーにする
    if (params[:reset_password_token].present? && resource.blank?) || (resource.present? && !resource.reset_password_period_valid?)
      return render './failure', locals: { alert: t('activerecord.errors.models.user.attributes.reset_password_token.invalid') }, status: :unprocessable_entity
    end

    # Tips: メールアドレス変更中でなく、メール未確認の場合は、確認済みにする
    resource.update!(confirmed_at: Time.now.utc) if resource.present? && resource.unconfirmed_email.blank? && resource.confirmed_at.blank?

    super
  end

  protected

  def render_create_error_missing_email
    # render_error(401, I18n.t('devise_token_auth.passwords.missing_email'))
    render './failure', locals: { alert: t('errors.messages.validate_password_params') }, status: :bad_request
  end

  def render_create_error_missing_redirect_url
    # render_error(401, I18n.t('devise_token_auth.passwords.missing_redirect_url'))
    render './failure', locals: { alert: t('devise_token_auth.passwords.missing_redirect_url') }, status: :unprocessable_entity
  end

  def render_error_not_allowed_redirect_url
    # render_error(422, I18n.t('devise_token_auth.passwords.not_allowed_redirect_url', redirect_url: @redirect_url), { status: 'error', data: resource_data })
    render './failure', locals: { alert: t('devise_token_auth.passwords.not_allowed_redirect_url') }, status: :unprocessable_entity
  end

  def render_create_success
    # render json: { success: true, message: success_message('passwords', @email) }
    render './users/auth/success', locals: { current_user: nil, notice: success_message('passwords', @email) }
  end

  # Tips: 未使用
  # def render_create_error(errors)
  #   # render json: { success: false, errors: errors }, status: 400
  #   render './failure', locals: { alert: errors }, status: :unprocessable_entity
  # end

  def render_edit_error
    # raise ActionController::RoutingError, 'Not Found'
    alert = t("activerecord.errors.models.user.attributes.reset_password_token.#{resource_params[:reset_password_token].blank? ? 'blank' : 'invalid'}")
    redirect_header_options = { reset_password: false, alert: alert }
    redirect_to DeviseTokenAuth::Url.generate(@redirect_url, redirect_header_options)
  end

  def render_update_error_unauthorized
    # render_error(401, 'Unauthorized')
    render './failure', locals: { alert: t('activerecord.errors.models.user.attributes.reset_password_token.invalid') }, status: :unprocessable_entity
  end

  # Tips: 未使用
  # def render_update_error_password_not_required
  #   # render_error(422, I18n.t('devise_token_auth.passwords.password_not_required', provider: @resource.provider.humanize))
  #   alert = t('devise_token_auth.passwords.password_not_required', provider: @resource.provider.humanize)
  #   render './failure', locals: { alert: alert }, status: :unprocessable_entity
  # end

  def render_update_error_missing_password
    # render_error(422, I18n.t('devise_token_auth.passwords.missing_passwords'))
    if params[:password].blank?
      errors = { password: t('activerecord.errors.models.user.attributes.password.blank') }
      errors[:full_messages] = ["#{t('activerecord.attributes.user.password')} #{errors[:password]}"]
    else
      errors = { password_confirmation: t('activerecord.errors.models.user.attributes.password_confirmation.confirmation') }
      errors[:full_messages] = ["#{t('activerecord.attributes.user.password_confirmation')} #{errors[:password_confirmation]}"]
    end
    render './failure', locals: { errors: errors, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
  end

  def render_update_success
    # render json: { success: true, data: resource_data, message: I18n.t('devise_token_auth.passwords.successfully_updated') }
    update_auth_header # Tips: 成功時のみ認証情報を返す

    alert = @resource.unconfirmed_email.present? ? t('devise.failure.unconfirmed') : nil
    render './users/auth/success', locals: { alert: alert, notice: t('devise_token_auth.passwords.successfully_updated') }
  end

  def render_update_error
    # render json: { success: false, errors: resource_errors }, status: 422
    render './failure', locals: { errors: resource_errors, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
  end

  private

  def render_not_found_error
    if Devise.paranoid
      # render_error(404, I18n.t('devise_token_auth.passwords.sended_paranoid'))
      render './failure', locals: { alert: t('devise_token_auth.passwords.sended_paranoid') }, status: :unprocessable_entity
    else
      # render_error(404, I18n.t('devise_token_auth.passwords.user_not_found', email: @email))
      errors = { email: t('devise_token_auth.passwords.user_not_found') }
      errors[:full_messages] = ["#{t('activerecord.attributes.user.email')} #{errors[:email]}"]
      render './failure', locals: { errors: errors, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
    end
  end

  def validate_redirect_url_param
    @redirect_url = params.fetch(:redirect_url, DeviseTokenAuth.default_password_reset_url)

    # return render_create_error_missing_redirect_url unless @redirect_url
    # return render_error_not_allowed_redirect_url if blacklisted_redirect_url?(@redirect_url)
  end
end
