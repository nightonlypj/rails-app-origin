class ApplicationAuthController < ApplicationController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token, unless: :format_html?
  before_action :response_not_acceptable_for_api_mode_not_api
  before_action :standard_devise_support
  prepend_before_action :response_not_acceptable_for_diff_format_accept
  prepend_before_action :update_request_uid_header

  private

  # APIのみモードでAPIリクエストでない場合、HTTPステータス406を返却
  def response_not_acceptable_for_api_mode_not_api
    head :not_acceptable if Settings.api_only_mode && format_html?
  end

  # リクエストに不整合がある場合、HTTPステータス406を返却
  def response_not_acceptable_for_diff_format_accept
    head :not_acceptable if (format_html? && !accept_header_html?) || (!format_html? && !accept_header_api?)
  end

  # 存在しない(404)を返却
  def response_not_found(alert = 'alert.page.notfound')
    return head :not_found if format_html?

    render './failure', locals: { alert: t(alert) }, status: :not_found
  end

  # URLの拡張子がない場合のみ、Device認証を有効にする（APIでCSRFトークン検証をしない為）
  def standard_devise_support
    DeviseTokenAuth.enable_standard_devise_support = format_html?
  end

  protected

  def render_authenticate_error
    return warden.authenticate!(scope: :user) if format_html?

    response_unauthenticated
  end
end
