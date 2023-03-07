class Member < ApplicationRecord
  attr_accessor :emails # NOTE: メンバー招待で使用

  belongs_to :space
  belongs_to :user
  belongs_to :invitationed_user, class_name: 'User', optional: true
  belongs_to :last_updated_user, class_name: 'User', optional: true

  validates :power, presence: true

  scope :search, lambda { |text, current_member|
    return if text&.strip.blank?

    collate = connection_db_config.configuration_hash[:adapter] == 'mysql2' ? ' COLLATE utf8_unicode_ci' : ''
    like = connection_db_config.configuration_hash[:adapter] == 'postgresql' ? 'ILIKE' : 'LIKE'
    sql = "users.name#{collate} #{like} ?"
    sql += " OR users.email#{collate} #{like} ?" if current_member.power_admin?

    member = all.joins(:user)
    text.split(/[[:blank:]]+/).each do |word|
      value = "%#{word}%"
      if current_member.power_admin?
        member = member.where(sql, value, value)
      else
        member = member.where(sql, value)
      end
    end

    member
  }
  scope :by_power, lambda { |power|
    return none if power.count.zero?
    return if power.count >= Member.powers.count

    where(power: power)
  }

  # 権限
  enum power: {
    admin: 1, # 管理者
    writer: 2, # 投稿者
    reader: 3 # 閲覧者
  }, _prefix: true

  # 最終更新日時
  def last_updated_at
    updated_at != created_at || (invitationed_at.present? && updated_at.floor != invitationed_at) ? updated_at : nil
  end
end
