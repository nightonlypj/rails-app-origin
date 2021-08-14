class Users::Auth::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token

  # POST /users/auth/confirmation メールアドレス確認[メール再送](処理)
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
