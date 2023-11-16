class DownloadsController < ApplicationAuthController
  before_action :response_not_acceptable_for_not_html, only: :new
  before_action :authenticate_user!
  before_action :set_params_new, only: :new
  before_action :set_params_create, only: :create

  # GET /downloads ダウンロード結果一覧
  # GET /downloads(.json) ダウンロード結果一覧API
  def index
    @id = (params[:id].to_s =~ /^[0-9]+$/).present? ? params[:id].to_i : nil
    @downloads = Download.where(user: current_user).search(@id).order(id: :desc)
                         .page(params[:page]).per(Settings.default_downloads_limit)

    if format_html? && @downloads.current_page > [@downloads.total_pages, 1].max
      return redirect_to @downloads.total_pages <= 1 ? downloads_path : downloads_path(page: @downloads.total_pages)
    end

    set_flash_index
  end

  # GET /downloads/file/:id(.csv) ダウンロードファイル取得
  def file
    @download = Download.find_by(id: params[:id])
    return response_not_found('alert.download.notfound') if @download.blank? || @download.user != current_user

    if @download.model.to_sym == :member
      current_member = Member.find_by(space: @download.space, user: current_user)
      return response_forbidden if current_member.blank? || !current_member.power_admin?
    end

    @download.last_downloaded_at = Time.current
    @download.save! # NOTE: 後続処理は時間が掛かるので、先にダウンロード済みにしておく

    send_data(@download.download_files.first.body, filename: "#{@download.model}_#{l(@download.requested_at, format: :file)}.#{@download.format}")
  end

  # GET /downloads/create ダウンロード依頼
  def new
    output_items = @items.stringify_keys.keys

    @download = Download.new(model: @model, space: @space, search_params: params[:search_params], select_items: params[:select_items],
                             target: @enable_target[0], format: :csv, char_code: :sjis, newline_code: :crlf, output_items:)
  end

  # POST /downloads/create ダウンロード依頼(処理)
  # POST /downloads/create(.json) ダウンロード依頼API(処理)
  def create
    @download = Download.new(download_params.merge(model: @model, space: @space, user: current_user, requested_at: Time.current))
    unless @download.save
      return render :new, status: :unprocessable_entity if format_html?

      return render './failure', locals: { errors: @download.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
    end

    DownloadJob.perform_later(@download.id)
    return redirect_to downloads_path(target_id: @download.id) if format_html?

    render locals: { notice: t('notice.download.create') }, status: :created
  end

  private

  def set_flash_index
    @alert = nil
    @notice = nil
    @target_id = params[:target_id].present? ? params[:target_id].to_i : nil
    return if @target_id.blank?

    @download = nil
    @downloads.each do |item| # NOTE: 一覧から取得。DBから取得するとstatusが異なる可能性がある為
      if item.id == @target_id
        @download = item
        break
      end
    end

    @download = Download.find_by(id: @target_id, user: current_user) if @download.blank?
    return if @download.blank? || @download.last_downloaded_at.present?

    if @download.status.to_sym == :failure
      @alert = t('alert.download.status.failure')
      flash[:alert] = @alert if format_html?
    else
      @notice = t("notice.download.status.#{@download.status}")
      flash[:notice] = @notice if format_html?
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_params_new(target_params = params)
    @model = target_params[:model]&.to_sym
    return response_param_error(:model, 'blank') if @model.blank?
    return response_param_error(:model, 'not_exist') if Download.models[@model].blank?

    if @model == :member
      return response_param_error(:space_code, 'blank') if target_params[:space_code].blank?

      @space = Space.find_by(code: target_params[:space_code])
      return response_param_error(:space_code, 'not_exist') if @space.blank?

      @current_member = Member.where(space: @space, user: current_user).eager_load(:user).first
      return response_forbidden if @current_member.blank? || !@current_member.power_admin?
    else
      # :nocov:
      @space = nil
      @current_member = nil
      # :nocov:
    end

    if format_html?
      @enable_target = []
      @enable_target.push('select') if target_params[:select_items].present?
      @enable_target.push('search') if target_params[:search_params].present?
      @enable_target.push('all')

      @items = t("items.#{@model}")
    end
  end

  def set_params_create
    set_params_new(params[:download])
  end

  def response_param_error(key, error)
    return head :not_found if format_html?

    render './failure', locals: { errors: { key => [t("errors.messages.param.#{error}")] }, alert: t('errors.messages.not_saved.one') }, status: :not_found
  end

  # Only allow a list of trusted parameters through.
  def download_params
    if format_html?
      params[:download][:output_items] = []
      @items.each do |key, _label|
        params[:download][:output_items].push(key.to_s) if params[:download]["output_items_#{key}"] == '1'
      end
      params[:download][:select_items] = params[:download][:select_items]&.split(',')
    end

    # NOTE: ArgumentError対策
    params[:download][:target]       = nil if Download.targets[params[:download][:target]].blank?
    params[:download][:format]       = nil if Download.formats[params[:download][:format]].blank?
    params[:download][:char_code]    = nil if Download.char_codes[params[:download][:char_code]].blank?
    params[:download][:newline_code] = nil if Download.newline_codes[params[:download][:newline_code]].blank?

    # NOTE: ActionController::Parametersの場合、permitでnilになる為
    params[:download][:output_items] = params[:download][:output_items].to_s if params[:download][:output_items].present?
    params[:download][:select_items] = params[:download][:select_items].to_s if params[:download][:select_items].present?
    params[:download][:search_params] = params[:download][:search_params].to_s if params[:download][:search_params].present?

    params.require(:download).permit(:target, :format, :char_code, :newline_code, :output_items, :search_params, :select_items)
  end
end
