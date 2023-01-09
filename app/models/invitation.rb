class Invitation < ApplicationRecord
  attr_accessor :ended_date, :ended_time, :ended_zone, :new_ended_at, :delete, :undo_delete

  belongs_to :space
  belongs_to :created_user,      class_name: 'User', optional: true # NOTE: アカウント削除済みでも変更できるようにoptionalを追加
  belongs_to :last_updated_user, class_name: 'User', optional: true

  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: true }
  validates :power, presence: true
  validates :memo, length: { maximum: Settings['invitation_memo_maximum'] }, if: proc { |invitation| invitation.memo.present? }
  validate :validate_ended_date
  validate :validate_ended_time

  # 権限
  enum power: {
    admin: 1, # 管理者
    writer: 2, # 投稿者
    reader: 3 # 閲覧者
  }, _prefix: true

  # ステータス
  def status
    return :email_joined if email_joined_at.present?
    return :deleted if destroy_schedule_at.present?
    return :expired if ended_at.present? && ended_at < Time.current

    :active
  end

  # ステータス（表示）
  def status_i18n
    I18n.t("enums.invitation.status.#{status}")
  end

  # ドメイン（配列）
  def domains_array
    domains.present? ? eval(domains) : []
  end

  # 最終更新日時
  def last_updated_at
    updated_at == created_at ? nil : updated_at
  end

  private

  def validate_ended_date
    return if ended_date.blank?

    result, @year, @month, @day = */^(\d+)-(\d+)-(\d+)$/.match(ended_date.gsub(%r{/}, '-'))
    result, @year, @month, @day = */^(\d{4})(\d{2})(\d{2})$/.match(ended_date) if result.blank?
    return errors.add(:ended_date, :invalid) if result.blank? || !(0..9999).cover?(@year.to_i) || !(1..12).cover?(@month.to_i) || !(1..31).cover?(@day.to_i)

    begin
      result = Time.new(@year, @month, @day, 23, 59, 59, ended_zone)
      return errors.add(:ended_date, :notfound) if result.day != @day.to_i # NOTE: 存在しない日付は丸められる為
      return errors.add(:ended_date, :before) if (ended_at.blank? || (ended_at&.strftime('%Y%m%d') != result.strftime('%Y%m%d'))) && result <= Time.current
    rescue StandardError
      errors.add(:ended_zone, :invalid)
    end
  end

  def validate_ended_time
    return if ended_date.blank?
    return errors.add(:ended_time, :blank) if ended_time.blank?

    result, hour, min = */^(\d+):(\d+)$/.match(ended_time)
    result, hour, min = */^(\d{2})(\d{2})$/.match(ended_time) if result.blank?
    return errors.add(:ended_time, :invalid) if result.blank? || !(0..23).cover?(hour.to_i) || !(0..59).cover?(min.to_i)
    return if errors[:ended_date].present?

    begin
      result = Time.new(@year, @month, @day, hour, min, 59, ended_zone)
      if (ended_at.blank? || (ended_at&.strftime('%Y%m%d%H%M') != result.strftime('%Y%m%d%H%M'))) && result <= Time.current
        return errors.add(:ended_time, :before)
      end

      self.new_ended_at = result
    rescue StandardError
      errors.add(:ended_zone, :invalid)
    end
  end
end
