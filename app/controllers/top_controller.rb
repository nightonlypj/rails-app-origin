class TopController < ApplicationController
  include InfomationsConcern
  before_action :response_not_found_for_api_mode_not_api, unless: :development?
  before_action :response_not_acceptable_for_not_html
  before_action :set_important_infomations

  # GET / トップページ
  def index
    render './layouts/_development', layout: 'none' if Settings.api_only_mode
  end

  private

  def development?
    Rails.env.development?
  end
end
