class InfomationsController < ApplicationAuthController
  # GET /infomations お知らせ一覧
  # GET /infomations(.json) お知らせ一覧API
  def index
    @infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_infomations_limit'])
                             .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                             .where('target = ? OR (target = ? AND user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], current_user&.id)
    return if request.format.json? || @infomations.current_page <= [@infomations.total_pages, 1].max

    redirect_to @infomations.total_pages <= 1 ? infomations_path : infomations_path(page: @infomations.total_pages)
  end

  # GET /infomations/1 お知らせ詳細
  # GET /infomations/1(.json) お知らせ詳細API
  def show
    @infomation = Infomation.find(params[:id])
    return head :not_found if @infomation.blank? || !@infomation.target_user?(current_user) || @infomation.started_at > Time.current
    return if @infomation.ended_at.blank? || @infomation.ended_at >= Time.current
    return render json: { success: false, alert: t('errors.messages.infomation.ended') }, status: :not_found if request.format.json?

    head :not_found
  end
end
