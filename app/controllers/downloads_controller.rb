class DownloadsController < ApplicationAuthController
  before_action :authenticate_user!
  before_action :set_download, only: %i[show edit update destroy]
  before_action :set_new, only: :new
  before_action :set_create, :validate_create, only: :create

  # GET /downloads ダウンロード結果一覧
  # GET /downloads(.json) ダウンロード結果一覧API
  def index
    @downloads = Download.all
    @downloads = Download.where(user: current_user)
                         .page(params[:page]).per(Settings['default_downloads_limit']).order(id: :desc)

    if format_html? && @downloads.current_page > [@downloads.total_pages, 1].max
      redirect_to @downloads.total_pages <= 1 ? downloads_path : downloads_path(page: @downloads.total_pages)
    end
  end

  # GET /downloads/file/:id ダウンロード
  # GET /downloads/file/:id(.json) ダウンロードAPI
  def file; end

  # GET /downloads/create ダウンロード依頼
  def new
    output_items = []
    @items.each { |key, _value| output_items.push(key.to_s) }

    @download = Download.new(model: @model, space: @space, search_params: params[:search_params], select_items: params[:select_items],
                             target: @enable_target[0], format: :csv, char: :sjis, newline: :crlf, output_items: output_items)
  end

  # POST /downloads/create ダウンロード依頼(処理)
  # POST /downloads/create(.json) ダウンロード依頼API(処理)
  def create
    @download.save!
    if format_html?
      redirect_to downloads_path, notice: t('notice.download.create')
    else
      render :create, locals: { notice: t('notice.download.create') }, status: :created
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_download
    @download = Download.find(params[:id])
  end

  def set_new(target_params = params)
    @model = target_params[:model]&.to_sym
    return head :not_found if Download.models[@model].blank?

    if @model == :member
      @space = Space.find_by(code: target_params[:space_code])
      return head :not_found if @space.blank?

      @current_member = Member.where(space: @space, user: current_user).eager_load(:user)&.first
      head :forbidden if @current_member.blank? || !@current_member.power_admin?
    else
      @space = nil
      @current_member = nil
    end

    @enable_target = []
    @enable_target.push('select') if target_params[:select_items].present?
    @enable_target.push('search') if target_params[:search_params].present?
    @enable_target.push('all')

    @items = t("items.#{@model}")
  end

  def set_create
    set_new(params[:download])
  end

  def validate_create
    if format_html?
      output_items = []
      @items.each { |key, _value| output_items.push(key.to_s) if params[:download]["output_items_#{key}"] == '1' }
    else
      output_items = params[:download][:output_items]&.split
    end

    @download = Download.new(download_params.merge(model: @model, space: @space, user: current_user, requested_at: Time.current, output_items: output_items))
    @download.valid?
    @download.errors.add(:output_items, t('activerecord.errors.models.download.attributes.output_items.blank')) if output_items.blank?

    if @download.errors.present?
      if format_html?
        render :new, status: :unprocessable_entity
      else
        render './failure', locals: { errors: @download.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
      end
    end
  end

  # Only allow a list of trusted parameters through.
  def download_params
    # ArgumentError対策
    params[:download][:target]  = nil if Download.targets[params[:download][:target]].blank?
    params[:download][:format]  = nil if Download.formats[params[:download][:format]].blank?
    params[:download][:char]    = nil if Download.chars[params[:download][:char]].blank?
    params[:download][:newline] = nil if Download.newlines[params[:download][:newline]].blank?

    params.require(:download).permit(:target, :format, :char, :newline, :search_params, :select_items)
  end
end
