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
    return '' unless enabled

    if subkey.present?
      resource.errors[key].any? || resource.errors[subkey].any? ? ' is-invalid' : ' is-valid'
    else
      resource.errors[key].any? ? ' is-invalid' : ' is-valid'
    end
  end

  # テキストのバリデーション表示のクラス名を返却 # Tips: radio_buttonやselectの項目名で使用
  def validate_text_class_name(enabled, resource, key, subkey = nil)
    return '' unless enabled

    if subkey.present?
      resource.errors[key].any? || resource.errors[subkey].any? ? ' text-danger' : ' text-success'
    else
      resource.errors[key].any? ? ' text-danger' : ' text-success'
    end
  end

  # パスワードのバリデーション表示のクラス名を返却 # Tips: パスワードは再入力で復元しない為
  def validate_password_class_name(enabled)
    enabled ? ' is-invalid' : ''
  end

  # 入力項目のサイズクラス名を返却
  def input_size_class_name(resource, key)
    resource.errors.any? && resource.errors[key].any? ? ' mb-5' : ' mb-3'
  end

  # 公開スペースのアイコンを返却
  def public_icon_tag(public_flag)
    if public_flag
      '<i class="fas fa-globe text-warning" data-mdb-toggle="tooltip" title="誰でも閲覧出来ます"></i>'
    else
      '<i class="fas fa-lock" data-mdb-toggle="tooltip" title="メンバーのみ閲覧出来ます"></i>'
    end
  end
end
