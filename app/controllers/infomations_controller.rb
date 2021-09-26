class InfomationsController < ApplicationAuthController
  # GET /infomations お知らせ一覧
  # GET /infomations(.json) お知らせ一覧API
  def index
    @infomations = Infomation.by_target_period.by_target_user(current_user).page(params[:page]).per(Settings['default_infomations_limit'])
    if format_html? && @infomations.current_page > [@infomations.total_pages, 1].max
      redirect_to @infomations.total_pages <= 1 ? infomations_path : infomations_path(page: @infomations.total_pages)
    end
  end

  # GET /infomations/1 お知らせ詳細
  # GET /infomations/1(.json) お知らせ詳細API
  def show
    @infomation = Infomation.find(params[:id])
    return head :not_found if @infomation.blank? || !@infomation.target_user?(current_user) || @infomation.started_at > Time.current

    if @infomation.ended_at.present? && @infomation.ended_at < Time.current
      return render './failure', locals: { alert: t('errors.messages.infomation.ended') }, status: :not_found if format_api?

      head :not_found
    end
  end
end
