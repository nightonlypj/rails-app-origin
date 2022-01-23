module UsersConcern
  extend ActiveSupport::Concern

  included do
    def unauthenticated_message
      if !Devise.paranoid && lock_strategy_enabled?(:failed_attempts) && (failed_attempts == self.class.maximum_attempts)
        :send_locked
      else
        super
      end
    end
  end
end
