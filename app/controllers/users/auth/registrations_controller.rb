# frozen_string_literal: true

class Users::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  include Users::RegistrationsConcern
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  before_action :configure_sign_up_params, only: %i[create]
  before_action :configure_account_update_params, only: %i[update]

  # POST /users/auth/sign_up アカウント登録(処理)
  def create
    params[:code] = create_unique_code(User, 'code', "Users::RegistrationsController.create #{params}")
    ActiveRecord::Base.transaction do # Tips: エラーでROLLBACKされなかった為
      super
    end
  end

  # PUT(PATCH) /users/auth/update 登録情報変更(処理)
  # def update
  #   super
  # end

  # DELETE /users/auth/destroy アカウント削除(処理)
  # def destroy
  #   super
  # end
end
