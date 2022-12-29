class Invitation < ApplicationRecord
  belongs_to :space
  belongs_to :created_user,      class_name: 'User', optional: true # NOTE: アカウント削除済みでも変更できるようにoptionalを追加
  belongs_to :last_updated_user, class_name: 'User', optional: true

  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: true }
  validates :power, presence: true

  # 権限
  enum power: {
    admin: 1, # 管理者
    writer: 2, # 投稿者
    reader: 3 # 閲覧者
  }, _prefix: true

  # ステータス
  def status
    return :deleted if deleted_at.present?
    return :expired if ended_at.present? && ended_at < Time.current

    :active
  end

  # ステータス（表示）
  def status_i18n
    I18n.t("enums.invitation.status.#{status}")
  end

  # 最終更新日時
  def last_updated_at
    updated_at == created_at ? nil : updated_at
  end
end
