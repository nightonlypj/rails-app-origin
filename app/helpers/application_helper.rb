module ApplicationHelper
  # 削除予約済みか返却
  def destroy_reserved?
    current_user.present? && current_user.destroy_reserved?
  end

  # 削除予約のメッセージを表示するかを返却
  def destroy_reserved_message?
    controller_name != 'registrations' && action_name != 'undo_delete' && destroy_reserved?
  end
end
