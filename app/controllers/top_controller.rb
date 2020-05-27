class TopController < ApplicationController
  before_action :set_use_space

  # GET / トップページ
  # @return index/index_subdomainテンプレート or not_found
  def index
    return head :not_found if !equal_base_domain && @use_space.blank?
    return render :index_subdomain unless equal_base_domain
  end
end
