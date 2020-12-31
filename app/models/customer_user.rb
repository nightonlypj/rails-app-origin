class CustomerUser < ApplicationRecord
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

  # 変更権限があるかを返却
  def update_power?(taget_user_power = nil)
    (power == 'Owner') || (power == 'Admin' && (taget_user_power.blank? || taget_user_power != 'Owner'))
  end
end
