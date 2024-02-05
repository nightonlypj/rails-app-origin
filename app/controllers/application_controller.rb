class ApplicationController < ActionController::Base
  include Application::LocaleConcern
  include Application::ResponseConcern
  around_action :switch_locale
  before_action :prepare_exception_notifier
  after_action :update_response_uid_header

  private

  # 例外通知に情報を追加
  def prepare_exception_notifier
    # :nocov:
    return if Rails.env.test?

    request.env['exception_notifier.exception_data'] = {
      current_user: { id: current_user&.id },
      url: request.url
    }
    # :nocov:
  end

  # ログイン後の遷移先
  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
      if resource.is_a?(AdminUser)
        rails_admin_url
      else
        super
      end
  end

  # ログアウト後の遷移先
  def after_sign_out_path_for(scope)
    if scope == :admin_user
      new_admin_user_session_path
    else
      new_user_session_path
    end
  end
end
