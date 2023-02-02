def new_logger(task_name)
  return Rails.logger if ENV['RAILS_LOG_TO_STDOUT'].present?

  Logger.new("log/#{task_name.gsub(/:/, '_')}_#{Rails.env}.log", level: Rails.logger.level)
end
