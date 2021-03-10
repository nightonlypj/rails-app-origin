class User < ApplicationRecord
  has_many :infomation, dependent: :destroy
  mount_uploader :image, ImageUploader

  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: true }
  validates :name, presence: true
  validates :name, length: { in: Settings['user_name_minimum']..Settings['user_name_maximum'] }, if: proc { |user| user.name.present? }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  # 削除予約済みか返却
  def destroy_reserved?
    destroy_schedule_at.present?
  end

  # 削除予約
  def set_destroy_reserve
    update!(destroy_requested_at: Time.current,
            destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days)
  end

  # 削除予約取り消し
  def set_undo_destroy_reserve
    update!(destroy_requested_at: nil,
            destroy_schedule_at: nil)
  end

  # 画像URLを返却
  def image_url(version)
    case version
    when :mini
      image? ? image.mini.url : "/images/user/#{version}_noimage.jpg"
    when :small
      image? ? image.small.url : "/images/user/#{version}_noimage.jpg"
    when :medium
      image? ? image.medium.url : "/images/user/#{version}_noimage.jpg"
    when :large
      image? ? image.large.url : "/images/user/#{version}_noimage.jpg"
    when :xlarge
      image? ? image.xlarge.url : "/images/user/#{version}_noimage.jpg"
    else
      logger.warn("[WARN]Not found: User.image_url(#{version})")
      ''
    end
  end
end
