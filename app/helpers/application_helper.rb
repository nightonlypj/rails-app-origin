module ApplicationHelper
  # 有効なメールアドレス確認トークンかを返却
  # @return true: 有効期限内か、制限なし, false: 期限切れ
  def valid_confirmation_token?
    resource_class.confirm_within.blank? || (Time.now.utc <= resource.confirmation_sent_at.utc + resource_class.confirm_within)
  end

  # 削除予約のメッセージを表示するかを返却
  def destroy_reserved_message?(user = current_user)
    controller_name != 'registrations' && action_name != 'undo_delete' && user.present? && user.destroy_reserved?
  end

  # バリデーション表示のクラス名を返却
  def validate_class_name(enabled, resource, key, subkey = nil)
    if enabled && resource.errors.any?
      if subkey.present?
        resource.errors[key].any? || resource.errors[subkey].any? ? ' is-invalid' : ' is-valid'
      else
        resource.errors[key].any? ? ' is-invalid' : ' is-valid'
      end
    else
      ''
    end
  end

  # パスワードのバリデーション表示のクラス名を返却 # Tips: パスワードは再入力で復元しない為
  def validate_password_class_name(enabled, resource)
    enabled && resource.errors.any? ? ' is-invalid' : ''
  end

  # 入力項目のサイズクラス名を返却
  def input_size_class_name(resource, key)
    if resource.errors.any?
      resource.errors[key].any? ? ' mb-5' : ' mb-3'
    else
      ' mb-3'
    end
  end
end
