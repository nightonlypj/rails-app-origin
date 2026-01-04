module Utils::CreateUniqueCodeConcern
  extend ActiveSupport::Concern

  private

  # ユニークコードを作成して返却
  def create_unique_code(model, key, logger_message, length = nil)
    try_count = 1
    loop do
      code = Utils::UniqueCodeGenerator.base36_uuid
      # :nocov:
      code = code[0, length] if length.present?
      return code unless model.exists?(key => code)

      if try_count < 10
        logger.warn "[WARN](#{try_count})Not unique code(#{code}): #{logger_message}"
      elsif try_count >= 10
        logger.error "[ERROR](#{try_count})Not unique code(#{code}): #{logger_message}"
        return code
      end
      try_count += 1
      # :nocov:
    end
  end
end
