require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    ### START ###
    config.i18n.fallbacks = true
    config.i18n.default_locale = :ja
    config.time_zone = 'Tokyo'
    config.action_view.field_error_proc = proc { |html_tag, _instance| html_tag }
    config.active_job.queue_adapter = :delayed_job

    # NOTE: Devise Token Authが対応していない為 -> ActionController::Redirecting::UnsafeRedirectError
    config.action_controller.raise_on_open_redirects = false
    ### END ###

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
