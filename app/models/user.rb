class User < ApplicationRecord
  include UsersConcern

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable
  include DeviseTokenAuth::Concerns::User
  attr_accessor :redirect_url # Tips: /users/auth/{update,sign_in}で使用

  mount_uploader :image, ImageUploader
  has_many :infomation, dependent: :destroy

  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: true }
  validates :name, presence: true
  validates :name, length: { in: Settings['user_name_minimum']..Settings['user_name_maximum'] }, if: proc { |user| user.name.present? }

  scope :by_destroy_reserved, -> { where('destroy_schedule_at <= ?', Time.current) }

  # 削除予約済みか返却
  def destroy_reserved?
    destroy_schedule_at.present?
  end

  # 削除予約
  def set_destroy_reserve
    update!(destroy_requested_at: Time.current, destroy_schedule_at: Time.current + Settings['destroy_schedule_days'].days)
  end

  # 削除予約取り消し
  def set_undo_destroy_reserve
    update!(destroy_requested_at: nil, destroy_schedule_at: nil)
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

  # お知らせの未読数を返却
  def infomation_unread_count
    Infomation.by_target(self).by_unread(infomation_check_last_started_at).count
  end
end
