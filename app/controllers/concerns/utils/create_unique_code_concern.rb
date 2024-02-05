module Utils::CreateUniqueCodeConcern
  extend ActiveSupport::Concern

  private

  # ユニークコードを作成して返却
  def create_unique_code(model, key, logger_message, length = nil)
    try_count = 1
    loop do
      code = Digest::MD5.hexdigest(SecureRandom.uuid).to_i(16).to_s(36).rjust(25, '0') # NOTE: 16進数32桁を36進数25桁に変換
      # :nocov:
      code = code[0, length] if length.present?
      return code if model.where(key => code).blank?

      if try_count < 10
        logger.warn("[WARN](#{try_count})Not unique code(#{code}): #{logger_message}")
      elsif try_count >= 10
        logger.error("[ERROR](#{try_count})Not unique code(#{code}): #{logger_message}")
        return code
      end
      try_count += 1
      # :nocov:
    end
  end
end
