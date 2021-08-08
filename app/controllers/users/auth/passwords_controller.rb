class Users::Auth::PasswordsController < DeviseTokenAuth::PasswordsController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
end
