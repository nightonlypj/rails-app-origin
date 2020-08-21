# frozen_string_literal: true

class AdminUsers::ConfirmationsController < Devise::ConfirmationsController
  layout 'admin_users'

  # GET /admin_users/confirmation/new メールアドレス確認メール再送
  # def new
  #   super
  # end

  # POST /admin_users/confirmation メールアドレス確認メール再送(処理)
  # def create
  #   super
  # end

  # GET /admin_users/confirmation メールアドレス確認(処理)
  def show
    return redirect_to new_admin_user_session_path, alert: already_confirmed_message if already_confirmed?(params[:confirmation_token])
    return redirect_to new_admin_user_confirmation_path, alert: invalid_token_message unless valid_confirmation_token?(params[:confirmation_token])

    super
  end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end

  private

  # メールアドレス確認済みメッセージを返却
  def already_confirmed_message
    t('errors.messages.already_confirmed')
  end

  # トークンエラーメッセージを返却
  def invalid_token_message
    t('activerecord.errors.models.admin_user.attributes.confirmation_token.invalid')
  end
end
