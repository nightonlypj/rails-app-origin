class ApplicationAuthController < ApplicationController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token, unless: :format_html?
  prepend_before_action :not_acceptable_response
  prepend_before_action :update_request_uid_header
  before_action :standard_devise_support

  private

  # リクエストに不整合がある場合、HTTPステータス406を返却
  def not_acceptable_response
    if format_html?
      head :not_acceptable unless accept_header_html?
    else
      head :not_acceptable unless accept_header_api?
    end
  end

  # URLの拡張子がない場合のみ、Device認証を有効にする（APIでCSRFトークン検証をしない為）
  def standard_devise_support
    DeviseTokenAuth.enable_standard_devise_support = format_html?
  end
end
