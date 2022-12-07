class Space < ApplicationRecord
  mount_uploader :image, ImageUploader

  belongs_to :create_user,      class_name: 'User'
  belongs_to :last_update_user, class_name: 'User', optional: true
  has_many :members, dependent: :destroy
  has_many :users, through: :members
  has_many :downloads

  scope :by_target, lambda { |current_user, checked|
    return where(id: []) if (!checked[:public] && !checked[:private]) || (!checked[:join] && !checked[:nojoin]) || (!checked[:active] && !checked[:destroy])

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
  scope :search, lambda { |text|
    return if text&.strip.blank?

    space = all
    collate = connection_db_config.configuration_hash[:adapter] == 'mysql2' ? ' COLLATE utf8_unicode_ci' : ''
    like = connection_db_config.configuration_hash[:adapter] == 'postgresql' ? 'ILIKE' : 'LIKE'
    text.split(/[[:blank:]]+/).each do |word|
      value = "%#{word}%"
      space = space.where("name#{collate} #{like} ? OR description#{collate} #{like} ?", value, value)
    end

    space
  }
  scope :active, -> { where(destroy_schedule_at: nil) }
  scope :destroy_reserved, -> { where.not(destroy_schedule_at: nil) }

  # 削除予約済みか返却
  def destroy_reserved?
    destroy_schedule_at.present?
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
end
