class TopController < ApplicationController
  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  def index
    return head :not_found if !base_domain_request? && @request_space.blank?

    user_id = current_user.present? ? current_user.id : nil
    @infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(1).per(Settings['infomations_limit'])
                             .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                             .where('target = ? OR (target = ? AND user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], user_id)
    return render :index_subdomain unless base_domain_request?

    if user_id.present?
      @join_spaces = Space.order(sort_key: 'ASC', id: 'ASC').page(1).per(Settings['join_spaces_limit'])
                          .joins(customer: :member).where(members: { user_id: user_id })
    end
    @public_spaces = Space.where(public_flag: true).order(created_at: 'DESC', id: 'DESC').page(1).per(Settings['public_spaces_limit'])
  end
end
