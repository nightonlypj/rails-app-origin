# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /users/password/new パスワード再設定メール送信
  # def new
  #   super
  # end

  # POST /users/password パスワード再設定メール送信(処理)
  # def create
  #   super
  # end

  # GET /users/password/edit パスワード再設定
  def edit
    return redirect_to new_user_password_path, alert: invalid_token_message unless valid_token?(params[:reset_password_token])

    super
  end

  # PUT /users/password パスワード再設定(処理)
  def update
    return redirect_to new_user_password_path, alert: invalid_token_message unless valid_token?(resource_params[:reset_password_token])

    super
  end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  private

  # 有効なtokenかを返却
  # @return true: 有効期限内, false: 存在しないか、期限切れ
  def valid_token?(token)
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, token)
    resource = resource_class.find_by(reset_password_token: reset_password_token)
    resource.present? && resource.reset_password_period_valid?
  end

  # tokenエラーメッセージを返却
  def invalid_token_message
    t('activerecord.errors.models.user.attributes.reset_password_token.invalid')
  end
end
