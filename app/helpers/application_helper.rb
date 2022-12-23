module ApplicationHelper
  # 検索用のjsを使用するかを返却
  def enable_javascript_search?
    %w[spaces members].include?(controller_name) && action_name == 'index'
  end

  # 左メニューを開くかを返却
  def show_user_accordion?
    (controller_name == 'registrations' && action_name == 'edit') || (controller_name == 'sessions' && action_name == 'delete')
  end

  # アカウント削除予約メッセージを表示するかを返却
  def user_destroy_reserved_message?
    return false unless current_user&.destroy_reserved?

    controller_name != 'registrations' && action_name != 'undo_delete'
  end

  # スペース削除予約メッセージを表示するかを返却
  def space_destroy_reserved_message?
    return false unless @space&.destroy_reserved?

    case controller_name
    when 'spaces'
      !%w[index new create undo_delete undo_destroy].include?(action_name)
    when 'members'
      true
    else
      false
    end
  end

  # 有効なメールアドレス確認トークンかを返却
  def user_valid_confirmation_token?
    return false unless devise_mapping.confirmable? && current_user.pending_reconfirmation?

    User.confirm_within.blank? || (Time.now.utc <= current_user.confirmation_sent_at.utc + User.confirm_within)
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

  # パスワードのバリデーション表示のクラス名を返却 # NOTE: パスワードは再入力で復元しない為
  def validate_password_class_name(enabled)
    enabled ? ' is-invalid' : ''
  end

  # 入力項目のサイズクラス名を返却
  def input_size_class_name(resource, key)
    resource.errors.any? && resource.errors[key].any? ? ' mb-5' : ' mb-3'
  end

  # 縦並びの入力項目のサイズクラス名を返却
  def input_size_class_name_vertical(enabled, resource, key)
    return ' mb-3' unless enabled

    resource.errors.any? && resource.errors[key].any? ? ' mb-4' : ' mb-0'
  end

  # 文字列を省略して返却
  def text_truncate(text, length)
    return if length <= 0

    text.blank? || text.length <= length ? text : text[0, length].concat('...')
  end

  # ページの最初の番号を返却
  def first_page_number(models)
    ((models.limit_value * (models.current_page - 1)) + 1).to_s(:delimited)
  end

  # ページの最後の番号を返却
  def last_page_number(models)
    [models.current_page * models.limit_value, models.total_count].min.to_s(:delimited)
  end
end
