# frozen_string_literal: true

class Users::Auth::UnlocksController < DeviseTokenAuth::UnlocksController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :not_acceptable_response_not_api_accept, only: %i[create]
  prepend_before_action :not_acceptable_response_not_html_accept, only: %i[show]
  before_action :validate_redirect_url_param, only: %i[create show]

  # POST /users/auth/unlock(.json) アカウントロック解除API[メール再送](処理)
  def create
    return render_create_error_missing_email unless resource_params[:email]

    @email = get_case_insensitive_field_from_resource_params(:email)
    @resource = find_resource(:email, @email)

    if @resource
      yield @resource if block_given?

      @resource.send_unlock_instructions(
        email: @email,
        provider: 'email',
        redirect_url: @redirect_url, # Tips: 追加
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
      @resource.save!
      yield @resource if block_given?

      redirect_header_options = { unlock: true }
      redirect_to DeviseTokenAuth::Url.generate(@redirect_url, redirect_header_options) # Tips: 変更
    else
      render_show_error
    end
  end

  private

  def validate_redirect_url_param
    # give redirect value from params priority
    @redirect_url = params.fetch(
      :redirect_url,
      Settings['default_unlock_success_url']
    )

    return render_create_error_missing_redirect_url unless @redirect_url
    return render_error_not_allowed_redirect_url if blacklisted_redirect_url?(@redirect_url)
  end

  def render_create_error_missing_redirect_url
    render_error(401, I18n.t('devise_token_auth.unlocks.missing_redirect_url'))
  end

  def render_error_not_allowed_redirect_url
    response = {
      status: 'error',
      data: resource_data
    }
    message = I18n.t('devise_token_auth.unlocks.not_allowed_redirect_url', redirect_url: @redirect_url)
    render_error(422, message, response)
  end
end
