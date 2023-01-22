class Infomation < ApplicationRecord
  belongs_to :user, optional: true

  # ラベル
  enum label: {
    not: 0, # （なし）
    maintenance: 1, # メンテナンス
    hindrance: 2, # 障害
    other: 999 # その他
  }, _prefix: true

  # 対象
  enum target: {
    all: 1, # 全員
    user: 2 # 対象ユーザーのみ
  }, _prefix: true

  default_scope { order(started_at: :desc, id: :desc) }
  scope :by_target, lambda { |current_user|
    where('target = ? OR (target = ? AND user_id = ?)', targets[:all], targets[:user], current_user&.id)
      .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
  }
  scope :by_force, -> { where('force_started_at <= ? AND (force_ended_at IS NULL OR force_ended_at >= ?)', Time.current, Time.current) }
  scope :by_unread, lambda { |infomation_check_last_started_at|
    where('started_at > ?', infomation_check_last_started_at) if infomation_check_last_started_at.present?
  }

  # 表示対象かを返却
  def display_target?(current_user)
    target_all? || (target_user? && user_id == current_user&.id)
  end
end
