# frozen_string_literal: true

class Users::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  include Users::RegistrationsConcern
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  prepend_before_action :not_acceptable_response_not_api_accept
  before_action :configure_sign_up_params, only: %i[create]
  before_action :configure_account_update_params, only: %i[update]

  # POST /users/auth/sign_up(.json) アカウント登録API(処理)
  def create
    params[:code] = create_unique_code(User, 'code', "Users::RegistrationsController.create #{params}")
    ActiveRecord::Base.transaction do # Tips: エラーでROLLBACKされなかった為
      super
    end
  end

  # PUT(PATCH) /users/auth/update(.json) 登録情報変更API(処理)
  # def update
  #   super
  # end

  # DELETE /users/auth/destroy(.json) アカウント削除API(処理)
  # def destroy
  #   super
  # end
end
