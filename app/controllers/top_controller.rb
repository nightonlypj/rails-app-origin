class TopController < ApplicationController
  include InfomationsConcern
  before_action :response_not_acceptable_for_not_html
  before_action :set_important_infomations

  # GET / トップページ
  def index; end
end
