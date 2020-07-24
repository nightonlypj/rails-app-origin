class TopController < ApplicationController
  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  def index
    return head :not_found if !base_domain_request? && @request_space.blank?
    return render :index_subdomain unless base_domain_request?

    @new_spaces = Space.all.order(id: 'DESC').limit(Settings['new_spaces_limit'])
  end
end
