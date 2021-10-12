class ApplicationController < ActionController::Base
  private

  # URLの拡張子が.jsonか、acceptヘッダにapplication/jsonが含まれる（htmlや*がない）かを返却
  def format_api?
    request.format.json?
  end

  # URLの拡張子がないかを返却
  def format_html?
    request.format.html?
  end

  # acceptヘッダにJSONが含まれるかを返却
  def accept_header_api?
    %r{,application/json[,;]} =~ ",#{request.headers[:ACCEPT]},"
  end

  # acceptヘッダが空か、HTMLが含まれるかを返却
  def accept_header_html?
    request.headers[:ACCEPT].blank? || %r{,text/html[,;]} =~ ",#{request.headers[:ACCEPT]}," || %r{,\*/\*[,;]} =~ ",#{request.headers[:ACCEPT]},"
  end

  # acceptヘッダにJSONが含まれない場合、HTTPステータス406を返却
  def not_acceptable_response_not_api_accept
    head :not_acceptable unless (format_html? || format_api?) && accept_header_api?
  end

  # acceptヘッダにHTMLが含まれない場合、HTTPステータス406を返却
  def not_acceptable_response_not_html_accept
    head :not_acceptable unless format_html? && accept_header_html?
  end

  # 認証エラーを返却
  def unauthenticated_response
    render './failure', locals: { alert: t('devise.failure.unauthenticated') }, status: :unauthorized
  end

  # 認証済みエラーを返却
  def already_authenticated_response
    render './failure', locals: { alert: t('devise.failure.already_authenticated') }, status: :unauthorized
  end

  # パスワードリセットトークンのユーザーを返却
  def user_reset_password_token(token)
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, token)
    resource_class.find_by(reset_password_token: reset_password_token)
  end

  # 有効なパスワードリセットトークンかを返却
  def valid_reset_password_token?(token)
    user_reset_password_token(token)&.reset_password_period_valid?
  end

  # メールアドレス確認済みかを返却
  def already_confirmed?(token)
    resource = resource_class.find_by(confirmation_token: token)
    resource&.confirmed_at&.present? && resource&.confirmation_sent_at&.present? && (resource.confirmed_at > resource.confirmation_sent_at)
  end

  # 有効なメールアドレス確認トークンかを返却
  def valid_confirmation_token?(token)
    true if resource_class.confirm_within.blank?

    resource = resource_class.find_by(confirmation_token: token)
    resource&.confirmation_sent_at&.present? && (Time.now.utc <= resource.confirmation_sent_at.utc + resource_class.confirm_within)
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

  # 削除予約済みの場合、リダイレクトしてメッセージを表示
  def redirect_response_destroy_reserved
    redirect_to root_path, alert: t('alert.user.destroy_reserved') if current_user.destroy_reserved?
  end

  # 削除予約済みの場合、JSONでメッセージを返却
  def json_response_destroy_reserved
    render './failure', locals: { alert: t('alert.user.destroy_reserved') }, status: :unprocessable_entity if current_user&.destroy_reserved?
  end

  # 削除予約済みでない場合、リダイレクトしてメッセージを表示
  def redirect_response_not_destroy_reserved
    redirect_to root_path, alert: t('alert.user.not_destroy_reserved') unless current_user.destroy_reserved?
  end

  # 削除予約済みでない場合、JSONでメッセージを返却
  def json_response_not_destroy_reserved
    render './failure', locals: { alert: t('alert.user.not_destroy_reserved') }, status: :unprocessable_entity unless current_user&.destroy_reserved?
  end

  # ユニークコードを作成して返却
  def create_unique_code(model, key, logger_message)
    try_count = 1
    loop do
      code = Digest::MD5.hexdigest(SecureRandom.uuid)
      return code if model.where(key => code).blank?

      if try_count < 10
        logger.warn("[WARN](#{try_count})Not unique code(#{code}): #{logger_message}")
      elsif try_count >= 10
        logger.error("[ERROR](#{try_count})Not unique code(#{code}): #{logger_message}")
        return code
      end
      try_count += 1
    end
  end
end
