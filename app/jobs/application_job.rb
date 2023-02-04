class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # 例外通知
  rescue_from StandardError do |exception|
    ExceptionNotifier.notify_exception(exception)
  end
end
