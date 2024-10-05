class Infomation < ApplicationRecord
  belongs_to :user, optional: true

  validates :locale, inclusion: { in: Settings.locales.keys.map(&:to_s) + [nil] }
  validates :label, presence: true
  validates :title, presence: true
  validates :started_at, presence: true
  validates :target, presence: true
  validates :user, presence: true, if: -> { target_user? }

  scope :by_locale, ->(locale) { where(locale: [nil, locale]) }
  scope :by_target, ->(current_user) {
    where('target = ? OR (target = ? AND user_id = ?)', targets[:all], targets[:user], current_user&.id)
      .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
  }
  scope :by_force, -> { where('force_started_at <= ? AND (force_ended_at IS NULL OR force_ended_at >= ?)', Time.current, Time.current) }
  scope :by_unread, ->(infomation_check_last_started_at) {
    where('started_at > ?', infomation_check_last_started_at) if infomation_check_last_started_at.present?
  }

  # ラベル
  enum label: {
    not: 0,         # （なし）
    maintenance: 1, # メンテナンス
    hindrance: 2,   # 障害
    update: 3,      # アップデート
    other: 9        # その他
  }, _prefix: true

  # 対象
  enum target: {
    all: 1, # 全員
    user: 2 # 対象ユーザーのみ
  }, _prefix: true

  # 表示対象かを返却
  def display_target?(current_user)
    target_all? || (target_user? && user_id == current_user&.id)
  end
end
