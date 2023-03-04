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
    if format_html?
      head :not_acceptable unless accept_header_html?
    else
      head :not_acceptable unless accept_header_api?
    end
  end

  # 権限エラー(403)を返却
  def response_forbidden
    if format_html?
      head :forbidden
    else
      render './failure', locals: { alert: t('alert.user.forbidden') }, status: :forbidden
    end
  end

  # 存在しない(404)を返却
  def response_not_found(alert = 'alert.page.notfound')
    if format_html?
      head :not_found
    else
      render './failure', locals: { alert: t(alert) }, status: :not_found
    end
  end

  # URLの拡張子がない場合のみ、Device認証を有効にする（APIでCSRFトークン検証をしない為）
  def standard_devise_support
    DeviseTokenAuth.enable_standard_devise_support = format_html?
  end

  # スペースとユーザーのメンバー情報をセット
  def set_space_current_member
    @space = Space.find_by(code: params[:space_code])
    return response_not_found if @space.blank?

    @current_member = Member.where(space: @space, user: current_user).eager_load(:user)&.first
    response_forbidden if @current_member.blank?
  end

  protected

  def render_authenticate_error
    if format_html?
      warden.authenticate!({ scope: :user })
    else
      response_unauthenticated
    end
  end
end
