class TopController < ApplicationController
  before_action :set_use_space

  # GET / トップページ（ベースドメイン、サブドメイン）
  def index
    return head :not_found if !equal_base_domain && @use_space.blank?
    return render :index_subdomain unless equal_base_domain

    @new_spaces = Space.all.order(id: 'DESC').limit(Settings['new_spaces_limit'])
  end
end
