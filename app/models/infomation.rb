class Infomation < ApplicationRecord
  enum target: { All: 1, User: 2 }
  belongs_to :user, optional: true
  belongs_to :action_user, class_name: 'User', optional: true
  belongs_to :customer, optional: true
  belongs_to :space, optional: true

  # 対象かを返却
  def target_user?(current_user)
    target == 'All' || (target == 'User' && current_user.present? && user_id == current_user.id)
  end

  # アクションに応じたタイトルを返却
  def action_title
    case action
    when 'MemberCreate' # メンバー招待
      get_title('infomation.action.member_create')
    when 'MemberUpdate' # メンバー権限変更
      get_title('infomation.action.member_update')
    when 'MemberDestroy' # メンバー解除
      get_title('infomation.action.member_destroy')
    when 'RegistrationCreate' # メンバー登録
      get_title('infomation.action.registration_create')
    when nil
      title
    else
      logger.warn("[WARN]Not found: Infomation.action_title(#{action})")
      nil
    end
  end

  private

  # タイトルの動的要素を置き換えて返却
  def get_title(key)
    I18n.t(key)
        .gsub(/%{action_user_name}/, action_user.present? ? action_user.name : I18n.t('infomation.action_user.blank.name'))
        .gsub(/%{action_user_email}/, action_user.present? ? action_user.email : I18n.t('infomation.action_user.blank.email'))
        .gsub(/%{customer_name}/, customer.present? ? customer.name : I18n.t('infomation.customer.blank.name'))
        .gsub(/%{customer_code}/, customer.present? ? customer.code : I18n.t('infomation.customer.blank.code'))
  end
end
