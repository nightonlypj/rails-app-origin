# frozen_string_literal: true

class Users::Auth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :not_acceptable_response_not_api_accept, only: %i[create]
  prepend_before_action :not_acceptable_response_not_html_accept, only: %i[show]

  # POST /users/auth/confirmation(.json) メールアドレス確認API[メール再送](処理)
  # def create
  #   super
  # end

  # GET /users/auth/confirmation メールアドレス確認(処理)
  def show
    ActiveRecord::Base.transaction do # Tips: エラーでROLLBACKされなかった為
      super
    end
  end
end
