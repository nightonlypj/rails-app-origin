class ApplicationAuthController < ApplicationController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token, if: :format_api?
  prepend_before_action :not_acceptable_response_not_api_accept, if: :format_api?
  prepend_before_action :update_request_uid_header
  before_action :standard_devise_support

  private

  # URLの拡張子がない場合のみ、Device認証を有効にする（APIでCSRFトークン検証をしない為）
  def standard_devise_support
    DeviseTokenAuth.enable_standard_devise_support = format_html?
  end
end
