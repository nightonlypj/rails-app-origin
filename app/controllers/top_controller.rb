class TopController < ApplicationController
  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  def index
    return head :not_found if !base_domain_request? && @request_space.blank?

    user_id = current_user.present? ? current_user.id : nil
    @new_infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(1).per(Settings['new_infomations_limit'])
                                 .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                                 .where('target = ? OR (target = ? AND user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], user_id)
    return render :index_subdomain unless base_domain_request?

    @new_spaces = Space.order(id: 'DESC').page(1).per(Settings['new_spaces_limit'])
  end
end
