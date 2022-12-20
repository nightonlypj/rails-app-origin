class ApplicationController < ActionController::Base
  after_action :update_response_uid_header

  private

  # リクエストのuidヘッダを[id+36**2](36進数)からuidに変更 # NOTE: uidがメールアドレスだと、メールアドレス確認後に認証に失敗する為
  def update_request_uid_header
    return if request.headers['uid'].blank?

    user = User.find_by(id: request.headers['uid'].to_i(36) - (36**2))
    request.headers['uid'] = user&.uid
  end

  # レスポンスのuidヘッダをuidから[id+36**2](36進数)に変更
  def update_response_uid_header
    return if response.headers['uid'].blank?

    user = User.find_by(uid: response.headers['uid'])
    response.headers['uid'] = user.present? ? (user.id + (36**2)).to_s(36) : nil
  end

  # URLの拡張子がないかを返却
  def format_html?
    request.format.html?
  end

  # acceptヘッダにJSONが含まれる（ワイルドカード不可）かを返却
  def accept_header_api?
    !(%r{,application/json[,;]} =~ ",#{request.headers[:ACCEPT]},").nil?
  end

  # acceptヘッダが空か、HTMLが含まれる（ワイルドカード可）かを返却
  def accept_header_html?
    request.headers[:ACCEPT].blank? ||
      !(%r{,text/html[,;]} =~ ",#{request.headers[:ACCEPT]},").nil? ||
      !(%r{,\*/\*[,;]} =~ ",#{request.headers[:ACCEPT]},").nil?
  end

  # APIリクエストに不整合がある場合、HTTPステータス406を返却（明示的にAPIのみ対応にする場合に使用）
  def response_not_acceptable_for_not_api
    head :not_acceptable if format_html? || !accept_header_api?
  end

  # HTMLリクエストに不整合がある場合、HTTPステータス406を返却（明示的にHTMLのみ対応にする場合に使用）
  def response_not_acceptable_for_not_html
    head :not_acceptable if !format_html? || !accept_header_html?
  end

  # 認証エラーを返却
  def response_unauthenticated
    render './failure', locals: { alert: t('devise.failure.unauthenticated') }, status: :unauthorized
  end

  # 認証済みエラーを返却
  def response_already_authenticated
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
    return true if resource_class.confirm_within.blank?

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
  def redirect_for_user_destroy_reserved(path = root_path)
    redirect_to path, alert: t('alert.user.destroy_reserved') if current_user.destroy_reserved?
  end

  # 削除予約済みの場合、JSONでメッセージを返却
  def response_api_for_user_destroy_reserved
    render './failure', locals: { alert: t('alert.user.destroy_reserved') }, status: :unprocessable_entity if current_user&.destroy_reserved?
  end

  # 削除予約済みでない場合、リダイレクトしてメッセージを表示
  def redirect_for_not_user_destroy_reserved
    redirect_to root_path, alert: t('alert.user.not_destroy_reserved') unless current_user.destroy_reserved?
  end

  # 削除予約済みでない場合、JSONでメッセージを返却
  def response_api_for_not_user_destroy_reserved
    render './failure', locals: { alert: t('alert.user.not_destroy_reserved') }, status: :unprocessable_entity unless current_user&.destroy_reserved?
  end

  # ユニークコードを作成して返却
  def create_unique_code(model, key, logger_message, length = nil)
    try_count = 1
    loop do
      code = Digest::MD5.hexdigest(SecureRandom.uuid).to_i(16).to_s(36).rjust(25, '0') # NOTE: 16進数32桁を36進数25桁に変換
      code = code[0, length] if length.present?
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
