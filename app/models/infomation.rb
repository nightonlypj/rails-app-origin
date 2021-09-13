class Infomation < ApplicationRecord
  belongs_to :user, optional: true
  enum target: { All: 1, User: 2 }

  # 対象かを返却
  def target_user?(current_user)
    target == 'All' || (target == 'User' && user_id == current_user&.id)
  end
end
