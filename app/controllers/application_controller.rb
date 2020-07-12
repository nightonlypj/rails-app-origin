class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :json_request?

  # JSONでリクエストされているかを返却
  # @return true: JSON, false: JSON以外
  def json_request?
    request.format.json?
  end

  # ベースドメインでリクエストされているかを返却
  # @return true: ベースドメイン, false: ベースドメイン以外（サブドメイン含む）
  def base_domain_request?
    request.host.eql?(Settings['base_domain'])
  end

  # ベースドメインにリダイレクト
  def redirect_base_domain_response
    redirect_to "//#{Settings['base_domain_link']}#{request.fullpath}" unless base_domain_request?
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
    head :not_found if json_request? && !base_domain_request?
  end

  # リクエストされたサブドメインの情報を返却
  # @return Spaceモデル
  def request_space
    subdomain = request.host[/^(.*)\.#{Settings['base_domain']}$/, 1]
    return if subdomain.blank?

    Space.find_by(subdomain: subdomain)
  end

  # リクエストされたサブドメインの情報をセット
  def set_request_space
    @request_space = request_space
  end

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
