class ApplicationController < ActionController::Base
  # ベースドメインでリクエストされているか返却
  # @return true: ベースドメイン, false: ベースドメイン以外（サブドメイン含む）
  def equal_base_domain
    request.domain.eql?(Settings['base_domain'])
  end

  # リクエストされたサブドメインの情報を返却
  # @return Spaceモデル
  def set_use_space
    return if equal_base_domain

    subdomain = request.domain[/^(.*)\.#{Settings['base_domain']}$/, 1]
    @use_space = Space.find_by(subdomain: subdomain)
  end
end
