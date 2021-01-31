class InfomationsController < ApplicationController
  # GET /infomations お知らせ一覧
  # GET /infomations.json お知らせ一覧API
  def index
    user_id = current_user.present? ? current_user.id : nil
    @infomations = Infomation.order(started_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_infomations_limit'])
                             .where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', Time.current, Time.current)
                             .where('target = ? OR (target = ? AND user_id = ?)', Infomation.targets[:All], Infomation.targets[:User], user_id)
    return if request.format.json? || @infomations.current_page <= [@infomations.total_pages, 1].max

    if @infomations.total_pages <= 1
      redirect_to infomations_path
    else
      redirect_to infomations_path(page: @infomations.total_pages)
    end
  end

  # GET /infomations/1 お知らせ詳細
  # GET /infomations/1.json お知らせ詳細API
  def show
    @infomation = Infomation.find(params[:id])
    return head :not_found if @infomation.blank? || !@infomation.target_user?(current_user) || @infomation.started_at > Time.current
    return if @infomation.ended_at.blank? || @infomation.ended_at >= Time.current
    return render json: { error: t('errors.messages.infomation.ended') }, status: :not_found if request.format.json?

    head :not_found
  end
end
