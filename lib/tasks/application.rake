def new_logger(task_name)
  # :nocov:
  return Rails.logger if ENV['RAILS_LOG_TO_STDOUT'].present?

  # :nocov:
  Logger.new("log/#{task_name.tr(':', '_')}_#{Rails.env}.log", level: Rails.logger.level)
end
