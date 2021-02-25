class TopController < ApplicationController
  before_action :authenticate_user!, if: :need_authenticate?
  before_action :not_found_outside_private_space
  before_action :set_join_spaces

  # GET /（ベースドメイン） トップページ
  # GET /（サブドメイン） スペーストップ
  def index
    user_id = current_user.present? ? current_user.id : nil
    @infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(1).per(Settings['infomations_limit'])
                             .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                             .where('target = ? OR (target = ? AND user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], user_id)
    return render :index_subdomain unless base_domain_request?

    @public_spaces = Space.where(public_flag: true).order(created_at: 'DESC', id: 'DESC').page(1).per(Settings['public_spaces_limit'])
    return if current_user.blank?

    @join_spaces = Space.order(sort_key: 'ASC', id: 'ASC').page(1).per(Settings['join_spaces_limit'])
                        .joins(customer: :member).where(members: { user_id: current_user.id })
  end

  private

  # 認証が必要かを返却
  def need_authenticate?
    !base_domain_request? && @request_space.present? && !@request_space.public_flag && !user_signed_in?
  end

  # 未参加の非公開スペースへのアクセス禁止
  def not_found_outside_private_space
    @member = @request_space.present? && current_user.present? ? Member.where(customer_id: @request_space.customer_id, user_id: current_user.id) : nil
    return head :not_found if !base_domain_request? && (@request_space.blank? || (!@request_space.public_flag && @member.count.zero?))
  end
end
