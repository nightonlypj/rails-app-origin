class TopController < ApplicationController
  include InfomationsConcern
  before_action :response_not_found_for_api_mode_not_api, unless: :development?
  before_action :response_not_acceptable_for_not_html
  before_action :render_development_for_api_mode, if: :development?
  before_action :set_important_infomations, unless: :api_only_mode?

  # GET / トップページ
  def index
    @public_spaces = Space.where(private: false).active.order(created_at: :desc, id: :desc)
                          .limit(Settings.default_spaces_limit)
  end

  private

  def render_development_for_api_mode
    # :nocov:
    render './layouts/_development', layout: 'none' if Settings.api_only_mode
    # :nocov:
  end

  def development?
    Rails.env.development?
  end

  def api_only_mode?
    Settings.api_only_mode
  end
end
