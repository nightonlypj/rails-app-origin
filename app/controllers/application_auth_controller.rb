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
    head :not_acceptable if (format_html? && !accept_header_html?) || (format_json? && !accept_header_json?) || (format_csv? && !accept_header_csv?)
  end

  # 権限エラー(403)を返却
  def response_forbidden
    return head :forbidden if format_html?

    render '/failure', locals: { alert: t('alert.user.forbidden') }, status: :forbidden, formats: :json
  end

  # 存在しない(404)を返却
  def response_not_found(alert = 'alert.page.notfound')
    return head :not_found if format_html?

    render '/failure', locals: { alert: t(alert) }, status: :not_found, formats: :json
  end

  # URLの拡張子がない場合のみ、Device認証を有効にする（APIでCSRFトークン検証をしない為）
  def standard_devise_support
    DeviseTokenAuth.enable_standard_devise_support = format_html?
  end

  # スペースとユーザーのメンバー情報をセット
  def set_space_current_member
    @space = Space.find_by(code: params[:space_code])
    return response_not_found if @space.blank?

    @current_member = Member.where(space: @space, user: current_user).eager_load(:user).first
    response_forbidden if @current_member.blank?
  end

  # スペースとユーザーのメンバー情報をセット（privateのみ認証必須）
  def set_space_current_member_auth_private(code = params[:space_code])
    @space = Space.find_by(code:)
    return response_not_found if @space.blank?
    return authenticate_user! if @space.private && !user_signed_in?

    @current_member = current_user.present? ? Member.find_by(space: @space, user: current_user) : nil
    response_forbidden if @space.private && @current_member.blank?
  end

  # 権限チェック（管理者）
  def check_power_admin
    response_forbidden unless @current_member&.power_admin?
  end

  protected

  def render_authenticate_error
    return warden.authenticate!(scope: :user) if format_html?

    response_unauthenticated
  end
end
