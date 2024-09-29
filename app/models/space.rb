class Space < ApplicationRecord
  mount_uploader :image, ImageUploader
  attr_accessor :image_delete

  belongs_to :created_user,      class_name: 'User', optional: true # NOTE: アカウント削除済みでも変更できるようにoptionalを追加
  belongs_to :last_updated_user, class_name: 'User', optional: true
  has_many :members, dependent: :destroy
  has_many :users, through: :members
  has_many :downloads, dependent: :destroy
  has_many :invitations, dependent: :destroy

  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: true }, allow_blank: true
  validates :name, presence: true
  validates :name, length: { in: Settings.space_name_minimum..Settings.space_name_maximum }, allow_blank: true
  validates :description, length: { maximum: Settings.space_description_maximum }, allow_blank: true
  validates :private, inclusion: { in: [true, false] } # NOTE: presenceだとfalseもエラーになる為

  # 名称（ユニーク）
  def validate_name_uniqueness(current_user)
    checked = { public: true, private: true, join: true, nojoin: true, active: true, destroy: false } # NOTE: 検索オプションと同じ
    errors.add(:name, :taken) if Space.by_target(current_user, checked).where(name:).exists?
  end

  scope :by_target, ->(current_user, checked) {
    return none if (!checked[:public] && !checked[:private]) || (!checked[:join] && !checked[:nojoin]) || (!checked[:active] && !checked[:destroy])

    if checked[:public] && checked[:private] && current_user.present?
      space = where(private: false).left_joins(:members).or(where(members: { user: current_user }))
    elsif checked[:public]
      space = where(private: false).left_joins(:members)
    elsif checked[:private]
      space = where(private: true).left_joins(:members).where(members: { user: current_user })
    end

    if checked[:join] && !checked[:nojoin]
      space = space.where(members: { user: current_user })
    elsif !checked[:join] && checked[:nojoin]
      join_space = left_joins(:members).where(members: { user: current_user })
      space = space.where.not(id: join_space.ids)
    end

    if checked[:active] && !checked[:destroy]
      space = space.active
    elsif !checked[:active] && checked[:destroy]
      space = space.destroy_reserved
    end

    space.distinct
  }
  scope :search, ->(text) {
    return if text&.strip.blank?

    sql = "name #{search_like} ? OR description #{search_like} ?"

    space = all
    text.split(/[[:blank:]]+/).each do |word|
      value = "%#{word}%"
      space = space.where(sql, value, value)
    end

    space
  }
  scope :active, -> { where(destroy_schedule_at: nil) }
  scope :destroy_reserved, -> { where.not(destroy_schedule_at: nil) }
  scope :destroy_target, -> { where(destroy_schedule_at: ..Time.current) }

  # 削除予約済みか返却
  def destroy_reserved?
    destroy_schedule_at.present?
  end

  # 削除予約
  def set_destroy_reserve!
    update!(destroy_requested_at: Time.current, destroy_schedule_at: Time.current + Settings.space_destroy_schedule_days.days)
  end

  # 削除予約取り消し
  def set_undo_destroy_reserve!
    update!(destroy_requested_at: nil, destroy_schedule_at: nil)
  end

  # 画像URLを返却
  def image_url(version)
    case version
    when :mini
      image? ? image.mini.url : "/images/space/#{version}_noimage.jpg"
    when :small
      image? ? image.small.url : "/images/space/#{version}_noimage.jpg"
    when :medium
      image? ? image.medium.url : "/images/space/#{version}_noimage.jpg"
    when :large
      image? ? image.large.url : "/images/space/#{version}_noimage.jpg"
    when :xlarge
      image? ? image.xlarge.url : "/images/space/#{version}_noimage.jpg"
    else
      logger.warn("[WARN]Not found: Space.image_url(#{version})")
      ''
    end
  end

  # 最終更新日時
  def last_updated_at
    updated_at == created_at ? nil : updated_at
  end
end
