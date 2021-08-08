class Users::Auth::UnlocksController < DeviseTokenAuth::UnlocksController
  include DeviseTokenAuth::Concerns::SetUserByToken
  skip_before_action :verify_authenticity_token
end
