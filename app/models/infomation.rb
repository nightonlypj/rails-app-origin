class Infomation < ApplicationRecord
  belongs_to :user, optional: true
  enum target: { All: 1, User: 2 }

  default_scope { order(started_at: :desc, id: :desc) }
  scope :by_target_period, -> { where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current) }
  scope :by_target_user, ->(current_user) { where('target = ? OR (target = ? AND user_id = ?)', targets[:All], targets[:User], current_user&.id) }

  # 対象ユーザーかを返却
  def target_user?(current_user)
    target == 'All' || (target == 'User' && user_id == current_user&.id)
  end
end
