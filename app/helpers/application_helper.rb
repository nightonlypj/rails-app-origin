module ApplicationHelper
  # 有効なメールアドレス確認トークンかを返却
  # @return true: 有効期限内か、制限なし, false: 期限切れ
  def valid_confirmation_token?
    resource_class.confirm_within.blank? || (Time.now.utc <= resource.confirmation_sent_at.utc + resource_class.confirm_within)
  end

  # 削除予約済みか返却
  def destroy_reserved?
    current_user.present? && current_user.destroy_reserved?
  end

  # 削除予約のメッセージを表示するかを返却
  def destroy_reserved_message?
    controller_name != 'registrations' && action_name != 'undo_delete' && destroy_reserved?
  end
end
