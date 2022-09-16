class Member < ApplicationRecord
  belongs_to :space
  belongs_to :user
  belongs_to :invitation_user, class_name: 'User', optional: true

  # 権限
  enum power: {
    admin: 1, # 管理者
    writer: 2, # 投稿者
    reader: 3 # 閲覧者
  }, _prefix: true

  scope :search, lambda { |text, current_member|
    return if text&.strip.blank?

    member = all.joins(:user)
    collate = connection_db_config.configuration_hash[:adapter] == 'mysql2' ? ' COLLATE utf8_unicode_ci' : ''
    like = connection_db_config.configuration_hash[:adapter] == 'postgresql' ? 'ILIKE' : 'LIKE'
    text.split(/[[:blank:]]+/).each do |word|
      value = "%#{word}%"
      if current_member.power_admin?
        member = member.where("users.name#{collate} #{like} ? OR users.email#{collate} #{like} ?", value, value)
      else
        member = member.where("users.name#{collate} #{like} ?", value)
      end
    end

    member
  }
end
