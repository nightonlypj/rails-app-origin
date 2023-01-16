class DownloadsController < ApplicationAuthController
  before_action :response_not_acceptable_for_not_html, only: :new
  before_action :authenticate_user!
  before_action :set_params_new, only: :new
  before_action :set_params_create, only: :create

  # GET /downloads ダウンロード結果一覧
  # GET /downloads(.json) ダウンロード結果一覧API
  def index
    @downloads = Download.where(user: current_user)
                         .page(params[:page]).per(Settings['default_downloads_limit']).order(id: :desc)

    if format_html? && @downloads.current_page > [@downloads.total_pages, 1].max
      return redirect_to @downloads.total_pages <= 1 ? downloads_path : downloads_path(page: @downloads.total_pages)
    end

    @download = nil
    if format_html? && params[:id].present?
      @downloads.each do |item| # NOTE: 一覧から取得。DBから取得するとstatusが異なる可能性がある為
        if item.id == params[:id].to_i
          @download = item
          break
        end
      end
      @download = Download.where(id: params[:id], user: current_user).first if @download.blank?
      flash[:notice] = @download.present? && @download.last_downloaded_at.blank? ? t("notice.download.status.#{@download.status}") : nil
    end
  end

  # GET /downloads/file/:id ダウンロード
  # GET /downloads/file/:id(.json) ダウンロードAPI
  def file
    @download = Download.find_by(id: params[:id])
    return response_not_found('alert.download.notfound') if @download.blank? || @download.user != current_user

    if @download.model.to_sym == :member
      current_member = Member.where(space: @download.space, user: current_user)&.first
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
                             target: @enable_target[0], format: :csv, char_code: :sjis, newline_code: :crlf, output_items: output_items)
  end

  # POST /downloads/create ダウンロード依頼(処理)
  # POST /downloads/create(.json) ダウンロード依頼API(処理)
  def create
    @download = Download.new(download_params.merge(model: @model, space: @space, user: current_user, requested_at: Time.current))
    unless @download.save
      if format_html?
        return render :new, status: :unprocessable_entity
      else
        return render './failure', locals: { errors: @download.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
      end
    end

    DownloadJob.perform_later(@download)
    if format_html?
      redirect_to downloads_path(id: @download.id)
    else
      render locals: { notice: t('notice.download.create') }, status: :created
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_params_new(target_params = params)
    @model = target_params[:model]&.to_sym
    return response_param_error(:model, 'blank') if @model.blank?
    return response_param_error(:model, 'not_exist') if Download.models[@model].blank?

    if @model == :member
      return response_param_error(:space_code, 'blank') if target_params[:space_code].blank?

      @space = Space.find_by(code: target_params[:space_code])
      return response_param_error(:space_code, 'not_exist') if @space.blank?

      @current_member = Member.where(space: @space, user: current_user).eager_load(:user)&.first
      return response_forbidden if @current_member.blank? || !@current_member.power_admin?
    else
      @space = nil
      @current_member = nil
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
    if format_html?
      head :not_found
    else
      render './failure', locals: { errors: { key => [t("errors.messages.param.#{error}")] }, alert: t('errors.messages.not_saved.one') }, status: :not_found
    end
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
