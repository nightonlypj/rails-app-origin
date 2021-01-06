class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :json_request?
  before_action :set_request_space

  private

  # JSONでリクエストされているかを返却
  # @return true: JSON, false: JSON以外
  def json_request?
    request.format.json?
  end

  # ベースドメインでリクエストされているかを返却
  # @return true: ベースドメイン, false: ベースドメイン以外（サブドメイン含む）
  def base_domain_request?
    request.host_with_port.eql?(Settings['base_domain'])
  end

  # リクエストされたドメインのスペース情報を返却
  # @return Spaceモデル
  def request_space
    subdomain = request.host_with_port[/^(.*)\.#{Settings['base_domain']}$/, 1]
    return if subdomain.blank?

    Space.find_by(subdomain: subdomain)
  end

  # リクエストされたドメインのスペース情報をセット
  def set_request_space
    @request_space = request_space
  end

  # ベースドメインにリダイレクト
  def redirect_base_domain_response
    redirect_to "//#{Settings['base_domain']}#{request.fullpath}" unless base_domain_request?
  end

  # ベースドメイン禁止
  def not_found_base_domain_response
    head :not_found if base_domain_request?
  end

  # サブドメイン禁止
  def not_found_sub_domain_response
    head :not_found unless base_domain_request?
  end

  # JSONの場合、サブドメイン禁止
  def not_found_json_sub_domain_response
    render json: { error: t('errors.messages.domain_error') }, status: :not_found if json_request? && !base_domain_request?
  end

  # 削除予約済みの場合、リダイレクトしてメッセージを表示
  def redirect_response_destroy_reserved
    redirect_to root_path, notice: t('notice.user.destroy_reserved') if current_user.destroy_reserved?
  end

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

  # ユニークコードを作成して返却
  # @return ハッシュ値（ユニークな値とならなかった場合は最後に作成した値を返却）
  def create_unique_code(model, key, logger_message)
    try_count = 1
    loop do
      code = Digest::MD5.hexdigest(SecureRandom.uuid)
      return code if model.where("#{key} = ?", code).blank?

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
