class Member < ApplicationRecord
  attr_accessor :emails

  belongs_to :space
  belongs_to :user
  belongs_to :invitationed_user, class_name: 'User', optional: true
  belongs_to :last_updated_user, class_name: 'User', optional: true

  validates :power, presence: true

  # メールアドレス
  def validate_emails
    result = []
    invalid_email = nil
    max_count = Settings.member_emails_max_count
    emails&.split(/\R/)&.each do |email|
      email.strip!
      if email.present? && !result.include?(email)
        result.push(email)
        break if result.count > max_count

        invalid_email = email if invalid_email.blank? && !Devise.email_regexp.match?(email)
      end
    end

    if result.blank?
      errors.add(:emails, :blank)
      return
    end
    if result.count > max_count
      errors.add(:emails, :max_count, count: max_count.to_s(:delimited))
      return
    end
    if invalid_email.present?
      errors.add(:emails, :invalid, email: invalid_email)
      return
    end

    result
  end

  scope :search, lambda { |text, current_member|
    return if text&.strip.blank?

    sql = "users.name #{search_like} ?"
    sql += " OR users.email #{search_like} ?" if current_member.power_admin?

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
    return none if power.count == 0
    return if power.count >= Member.powers.count

    where(power:)
  }
  scope :by_target, lambda { |checked|
    return none if !checked[:active] && !checked[:destroy]

    if checked[:active] && !checked[:destroy]
      joins(:user).merge(User.active)
    elsif !checked[:active] && checked[:destroy]
      joins(:user).merge(User.destroy_reserved)
    else
      all
    end
  }

  # 権限
  POWER_WRITER_UP = %i[admin writer].freeze
  enum power: {
    admin: 1,  # 管理者
    writer: 2, # 投稿者
    reader: 3  # 閲覧者
  }, _prefix: true

  # 最終更新日時
  def last_updated_at
    updated_at != created_at || (invitationed_at.present? && updated_at.floor != invitationed_at) ? updated_at : nil
  end
end
