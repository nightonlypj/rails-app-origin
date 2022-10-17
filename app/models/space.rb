class Space < ApplicationRecord
  mount_uploader :image, ImageUploader

  belongs_to :create_user,      class_name: 'User'
  belongs_to :last_update_user, class_name: 'User', optional: true
  has_many :members, dependent: :destroy
  has_many :users, through: :members
  has_many :downloads

  scope :by_target, lambda { |current_user, exclude_member_space|
    space = where(private: false)
    return space if current_user.blank?

    if exclude_member_space
      space.left_joins(:members).where(members: { user: nil }).distinct
    else
      space.left_joins(:members).or(where(members: { user: current_user })).distinct
    end
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
