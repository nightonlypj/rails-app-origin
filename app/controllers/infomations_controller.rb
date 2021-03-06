class InfomationsController < ApplicationAuthController
  include InfomationsConcern
  prepend_before_action :not_acceptable_response_not_api_accept, only: %i[important]
  before_action :set_important_infomations, only: %i[important]

  # GET /infomations お知らせ一覧
  # GET /infomations(.json) お知らせ一覧API
  def index
    @infomations = Infomation.by_target(current_user).page(params[:page]).per(Settings['default_infomations_limit'])
    update_infomation_check

    if format_html? && @infomations.current_page > [@infomations.total_pages, 1].max
      redirect_to @infomations.total_pages <= 1 ? infomations_path : infomations_path(page: @infomations.total_pages)
    end
  end

  # GET /infomations/important(.json) 大切なお知らせAPI
  # def important
  # end

  # GET /infomations/1 お知らせ詳細
  # GET /infomations/1(.json) お知らせ詳細API
  def show
    @infomation = Infomation.find(params[:id])
    return head :not_found if @infomation.blank? || !@infomation.target_user?(current_user) || @infomation.started_at > Time.current

    if @infomation.ended_at.present? && @infomation.ended_at < Time.current
      return head :not_found if format_html?

      render './failure', locals: { alert: t('errors.messages.infomation.ended') }, status: :not_found
    end
  end

  private

  # お知らせ確認情報更新
  def update_infomation_check
    return if current_user.blank? || @infomations.blank? || @infomations.current_page != 1

    current_user.infomation_check_last_started_at = @infomations.first.started_at
    current_user.save!
  end
end
