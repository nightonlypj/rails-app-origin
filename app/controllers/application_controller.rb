class ApplicationController < ActionController::Base
  private

  # 有効なパスワードリセットトークンかを返却
  # @return true: 有効期限内, false: 存在しないか、期限切れ
  def valid_reset_password_token?(token)
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, token)
    resource = resource_class.find_by(reset_password_token: reset_password_token)
    resource.present? && resource.reset_password_period_valid?
  end

  # メールアドレス確認済みかを返却
  # @return true: 確認済み, false: 未確認か、存在しない
  def already_confirmed?(token)
    resource = resource_class.find_by(confirmation_token: token)
    resource.present? && resource.confirmed_at.present? && resource.confirmation_sent_at.present? && (resource.confirmed_at > resource.confirmation_sent_at)
  end

  # 有効なメールアドレス確認トークンかを返却
  # @return true: 有効期限内か、制限なし, false: 存在しないか、期限切れ
  def valid_confirmation_token?(token)
    true if resource_class.confirm_within.blank?

    resource = resource_class.find_by(confirmation_token: token)
    resource.present? && resource.confirmation_sent_at.present? && (Time.now.utc <= resource.confirmation_sent_at.utc + resource_class.confirm_within)
  end

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
