# frozen_string_literal: true

class Users::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  include Users::RegistrationsConcern
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :unauthenticated_response, only: %i[show update image_update image_destroy destroy undo_destroy], unless: :user_signed_in?
  prepend_before_action :already_authenticated_response, only: %i[create], if: :user_signed_in?
  prepend_before_action :not_acceptable_response_not_api_accept
  prepend_before_action :update_request_uid_header
  before_action :json_response_destroy_reserved, only: %i[update image_update image_destroy destroy]
  before_action :json_response_not_destroy_reserved, only: %i[undo_destroy]
  before_action :configure_sign_up_params, only: %i[create]
  before_action :configure_account_update_params, only: %i[update]
  skip_after_action :update_auth_header, only: %i[update image_update]

  # POST /users/auth/sign_up(.json) アカウント登録API(処理)
  def create
    params[:code] = create_unique_code(User, 'code', "Users::RegistrationsController.create #{params}")
    ActiveRecord::Base.transaction do # Tips: エラーでROLLBACKされなかった為
      super
    end
  end

  # GET /users/auth/show(.json) 登録情報詳細API
  def show
    render './users/auth/show'
  end

  # PUT(PATCH) /users/auth/update(.json) 登録情報変更API(処理)
  def update
    # Tips: 存在するメールアドレスの場合はエラーにする
    if @resource.present? && @resource.email != params[:email] && User.find_by(email: params[:email]).present?
      errors = { email: t('activerecord.errors.models.user.attributes.email.exist') }
      errors[:full_messages] = ["#{t('activerecord.attributes.user.email')} #{errors[:email]}"]
      return render './failure', locals: { errors: errors, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
    end

    params[:password_confirmation] = '' if params[:password_confirmation].nil? # Tips: nilだとチェックされずに保存される為
    params[:current_password] = '' if params[:current_password].nil? # Tips: nilだとチェックされずに保存される為
    super
  end

  # POST /users/auth/image/update(.json) 画像変更API(処理)
  def image_update
    if params[:image].blank? || params[:image].class != ActionDispatch::Http::UploadedFile
      errors = { image: t('errors.messages.image_update_blank') }
      errors[:full_messages] = ["#{t('activerecord.attributes.user.image')} #{errors[:image]}"]
      return render './failure', locals: { errors: errors, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
    end

    @user = User.find(@resource.id)
    if @user.update(params.permit(:image))
      update_auth_header # Tips: 成功時のみ認証情報を返す
      render './users/auth/success', locals: { notice: t('notice.user.image_update') }
    else
      render './failure', locals: { errors: @user.errors, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
    end
  end

  # DELETE /users/auth/image/delete(.json) 画像削除API(処理)
  def image_destroy
    @user = User.find(@resource.id)
    @user.remove_image!
    @user.save!
    render './users/auth/success', locals: { notice: t('notice.user.image_destroy') }
  end

  # DELETE /users/auth/delete(.json) アカウント削除API(処理)
  def destroy
    if @resource
      # @resource.destroy
      @resource.set_destroy_reserve
      UserMailer.with(user: @resource).destroy_reserved.deliver_now

      yield @resource if block_given?
      render_destroy_success
    else
      render_destroy_error
    end
  end

  # DELETE /users/auth/undo_delete(.json) アカウント削除取り消しAPI(処理)
  def undo_destroy
    @resource.set_undo_destroy_reserve
    UserMailer.with(user: @resource).undo_destroy_reserved.deliver_now

    render './users/auth/success', locals: { notice: t('devise.registrations.undo_destroy_reserved') }
  end

  protected

  def render_create_error_missing_confirm_success_url
    # render_error(422, I18n.t('devise_token_auth.registrations.missing_confirm_success_url'), { status: 'error', data: resource_data })
    render './failure', locals: { alert: t('devise_token_auth.registrations.missing_confirm_success_url') }, status: :unprocessable_entity
  end

  def render_create_error_redirect_url_not_allowed
    # alert = t('devise_token_auth.registrations.redirect_url_not_allowed', redirect_url: @redirect_url)
    # render_error(422, alert, { status: 'error', data: resource_data })
    render './failure', locals: { alert: t('devise_token_auth.registrations.redirect_url_not_allowed') }, status: :unprocessable_entity
  end

  def render_create_success
    # render json: { status: 'success', data: resource_data }
    render './users/auth/success', locals: { notice: t('devise.registrations.signed_up_but_unconfirmed') }
  end

  def render_create_error
    # render json: { status: 'error', data: resource_data, errors: resource_errors }, status: 422
    render './failure', locals: { errors: resource_errors, alert: t('errors.messages.not_saved.one') }, status: :unprocessable_entity
  end

  def render_update_success
    # render json: { status: 'success', data: resource_data }
    update_auth_header # Tips: 成功時のみ認証情報を返す

    notice = @resource.unconfirmed_email.present? ? 'devise.registrations.update_needs_confirmation' : 'devise.registrations.updated'
    render './users/auth/success', locals: { notice: t(notice) }
  end

  # Tips: 未使用
  # def render_update_error
  #   # render json: { status: 'error', errors: resource_errors }, status: 422
  #   render './failure', locals: { errors: resource_errors }, status: :unprocessable_entity
  # end

  # Tips: 未使用
  # def render_update_error_user_not_found
  #   # render_error(404, I18n.t('devise_token_auth.registrations.user_not_found'), status: 'error')
  #   render './failure', locals: { alert: t('devise_token_auth.registrations.user_not_found') }, status: :unprocessable_entity
  # end

  def render_destroy_success
    # render json: { success: true, notice: I18n.t('devise_token_auth.registrations.account_with_uid_destroyed', uid: @resource.uid) }
    render './users/auth/success', locals: { notice: t('devise.registrations.destroy_reserved') }
  end

  def render_destroy_error
    # render_error(404, I18n.t('devise_token_auth.registrations.account_to_destroy_not_found'), status: 'error')
    render './failure', locals: { alert: t('devise.failure.unauthenticated') }, status: :unprocessable_entity
  end

  private

  def validate_sign_up_params
    # validate_post_data sign_up_params, I18n.t('errors.messages.validate_sign_up_params')
    render './failure', locals: { alert: t('errors.messages.validate_sign_up_params') }, status: :bad_request if sign_up_params.empty?
  end

  def validate_account_update_params
    # validate_post_data account_update_params, I18n.t('errors.messages.validate_account_update_params')
    render './failure', locals: { alert: t('errors.messages.validate_account_update_params') }, status: :bad_request if account_update_params.empty?
  end
end
