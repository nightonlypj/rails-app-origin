class ApplicationController < ActionController::Base
  private

  # ログイン後の遷移先
  # @return 遷移元、またはトップページ（フロント・管理）
  def after_sign_in_path_for(resource)
    stored_location_for(resource) ||
      if resource.is_a?(AdminUser)
        rails_admin_url
      else
        super
      end
  end

  # ログアウト後の遷移先
  # @return ログインのパス（ユーザー・管理者）
  def after_sign_out_path_for(scope)
    if scope == :admin_user
      new_admin_user_session_path
    else
      new_user_session_path
    end
  end
end
