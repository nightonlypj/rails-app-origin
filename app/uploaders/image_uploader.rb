class ImageUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{"#{cache_dir}/" if Rails.env.test?}uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def cache_dir
    "/tmp/#{Settings['base_domain']}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url(*args)
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  BASE_WIDTH = 16
  BASE_HEIGHT = 16
  version :mini do
    process resize_and_pad: [BASE_WIDTH * 1.5, BASE_HEIGHT * 1.5]
  end
  version :small do
    process resize_and_pad: [BASE_WIDTH * 2, BASE_HEIGHT * 2]
  end
  version :medium do
    process resize_and_pad: [BASE_WIDTH * 4, BASE_HEIGHT * 4]
  end
  version :large do
    process resize_and_pad: [BASE_WIDTH * 8, BASE_HEIGHT * 8]
  end
  version :xlarge do
    process resize_and_pad: [BASE_WIDTH * 16, BASE_HEIGHT * 16]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_allowlist
    %w[jpg jpeg gif png]
  end

  def content_type_allowlist
    [%r{image/}]
  end

  def size_range
    1..(20.megabytes)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  private

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, Digest::MD5.hexdigest(SecureRandom.uuid))
  end
end
