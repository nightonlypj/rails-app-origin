module Devise::PasswordsConcern
  extend ActiveSupport::Concern

  private

  # パスワードリセットトークンのユーザーを返却
  def user_reset_password_token(token)
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, token)
    resource_class.find_by(reset_password_token:)
  end

  # 有効なパスワードリセットトークンかを返却
  def valid_reset_password_token?(token)
    user_reset_password_token(token)&.reset_password_period_valid?
  end
end
