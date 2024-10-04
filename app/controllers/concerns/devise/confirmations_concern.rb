module Devise::ConfirmationsConcern
  extend ActiveSupport::Concern

  private

  # メールアドレス確認済みかを返却
  def already_confirmed?(token)
    resource = resource_class.find_by(confirmation_token: token)
    resource&.confirmed_at&.present? && resource&.confirmation_sent_at&.present? && (resource.confirmed_at > resource.confirmation_sent_at)
  end

  # 有効なメールアドレス確認トークンかを返却
  def valid_confirmation_token?(token)
    # :nocov:
    return true if resource_class.confirm_within.blank?

    # :nocov:
    resource = resource_class.find_by(confirmation_token: token)
    resource&.confirmation_sent_at&.present? && (Time.now.utc <= resource.confirmation_sent_at.utc + resource_class.confirm_within)
  end
end
