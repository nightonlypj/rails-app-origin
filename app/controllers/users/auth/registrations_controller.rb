class Users::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
  before_action :configure_sign_up_params, only: %i[create]

  def create
    params[:code] = create_unique_code(User, 'code', "Users::RegistrationsController.create #{params}")
    ActiveRecord::Base.transaction do # Tips: エラーでROLLBACKされない為
      super
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[code name])
  end
end
