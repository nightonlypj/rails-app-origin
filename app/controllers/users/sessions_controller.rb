# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: :create
  prepend_before_action :response_not_found_for_api_mode_not_api

  # GET /users/sign_in ログイン
  def new
    # NOTE: createでvalidateエラーになると、メッセージがデフォルト言語に書き変わってしまう為
    if flash[:alert].present? && I18n.locale != I18n.default_locale
      t('devise.failure', locale: I18n.default_locale).each do |key, message|
        next if flash[:alert] != message

        flash[:alert] = t("devise.failure.#{key}", locale: I18n.locale)
        logger.debug("flash[:alert]: #{message} -> #{flash[:alert]}")
        break
      end
    end

    super
  end

  # POST /users/sign_in ログイン(処理)
  # def create
  #   super
  # end

  # GET /users/sign_out ログアウト
  def delete
    redirect_to root_path, alert: t('devise.sessions.already_signed_out') unless user_signed_in?
  end

  # POST /users/sign_out ログアウト(処理)
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
