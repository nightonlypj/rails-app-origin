class Space < ApplicationRecord
  mount_uploader :image, ImageUploader
  belongs_to :customer

  validates :subdomain, presence: true
  validates :subdomain, length: { in: Settings['subdomain_minimum']..Settings['subdomain_maximum'] }, if: proc { |space| space.subdomain.present? }
  validates :subdomain, format: { with: /\A[a-z\d][a-z\d\-]*\z/ }, if: proc { |space| space.subdomain.present? }
  validates :subdomain, uniqueness: true, if: proc { |space| space.subdomain.present? }
  validates :name, presence: true
  validates :name, length: { in: Settings['space_name_minimum']..Settings['space_name_maximum'] }, if: proc { |space| space.name.present? }
  validates :purpose, length: { in: Settings['space_purpose_minimum']..Settings['space_purpose_maximum'] }, if: proc { |space| space.purpose.present? }

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
      logger.warn("[WARN]Not found: space.image_url(#{version})")
      ''
    end
  end
end
