class Member < ApplicationRecord
  belongs_to :customer
  belongs_to :user
  enum power: { Owner: 1, Admin: 2, Member: 3 }

  # 登録日時を返却
  def registrationed_at
    if user.invitation_requested_at.present? && user.invitation_completed_at.blank?
      nil
    elsif user.invitation_customer_id == customer.id && user.invitation_completed_at.present?
      user.invitation_completed_at
    else
      created_at
    end
  end

  # 顧客情報変更の権限があるかを返却
  def customer_update_power?
    power == 'Owner'
  end

  # メンバー招待の権限があるかを返却
  def member_create_power?(taget_user_power = nil)
    (power == 'Owner') || (power == 'Admin' && (taget_user_power.blank? || taget_user_power != 'Owner'))
  end

  # メンバー権限変更の権限があるかを返却
  def member_update_power?(taget_user_power = nil)
    member_create_power?(taget_user_power)
  end

  # メンバー解除の権限があるかを返却
  def member_destroy_power?(taget_user_power = nil)
    member_create_power?(taget_user_power)
  end

  # スペース作成の権限があるかを返却
  def space_create_power?
    (power == 'Owner') || (power == 'Admin')
  end

  # スペース情報変更の権限があるかを返却
  def space_update_power?
    space_create_power?
  end
end
