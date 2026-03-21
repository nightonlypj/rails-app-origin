# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  include Devise::ConfirmationsConcern

  prepend_before_action :response_not_found_for_api_mode_not_api

  # メールアドレス確認[メール再送]
  # def new
  #   super
  # end

  # メールアドレス確認[メール再送](処理)
  # def create
  #   super
  # end

  # メールアドレス確認(処理)
  def show
    return redirect_to new_user_session_path, alert: t('errors.messages.already_confirmed') if already_confirmed?(params[:confirmation_token])
    unless valid_confirmation_token?(params[:confirmation_token])
      return redirect_to new_user_confirmation_path, alert: t('activerecord.errors.models.user.attributes.confirmation_token.invalid')
    end

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
end
