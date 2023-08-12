class SpacesController < ApplicationAuthController
  before_action :response_not_acceptable_for_not_html, only: %i[new edit delete undo_delete]
  before_action :authenticate_user!, only: %i[new create edit update delete destroy undo_delete undo_destroy]
  before_action :redirect_spaces_for_user_destroy_reserved, only: %i[new create], if: :format_html?
  before_action :response_api_for_user_destroy_reserved, only: %i[create update destroy undo_destroy], unless: :format_html?
  before_action :set_space_current_member_auth_private_code, only: %i[show edit update delete destroy undo_delete undo_destroy]
  before_action :redirect_space_for_user_destroy_reserved, only: %i[edit update delete destroy undo_delete undo_destroy], if: :format_html?
  before_action :redirect_space_for_space_destroy_reserved, only: %i[edit update delete destroy], if: :format_html?
  before_action :response_api_for_space_destroy_reserved, only: %i[update destroy], unless: :format_html?
  before_action :redirect_space_for_not_space_destroy_reserved, only: %i[undo_delete undo_destroy], if: :format_html?
  before_action :response_api_for_not_space_destroy_reserved, only: :undo_destroy, unless: :format_html?
  before_action :check_power_admin, only: %i[edit update delete destroy undo_delete undo_destroy]
  before_action :set_member_count, only: :show
  before_action :set_params_index, only: :index
  before_action :validate_params_create, only: :create
  before_action :validate_params_update, only: :update

  # GET /spaces スペース一覧
  # GET /spaces(.json) スペース一覧API
  def index
    @spaces = Space.by_target(current_user, @checked).search(@text).order(created_at: :desc, id: :desc)
                   .page(params[:page]).per(Settings.default_spaces_limit)
    @members = []
    if current_user.present?
      members = Member.where(space_id: @spaces.ids, user: current_user)
      @members = members.index_by(&:space_id)
    end

    if format_html? && @spaces.current_page > [@spaces.total_pages, 1].max
      redirect_to @spaces.total_pages <= 1 ? spaces_path : spaces_path(page: @spaces.total_pages)
    end
  end

  # GET /s/:code スペーストップ
  # GET /s/:code(.json) スペース詳細API
  def show; end

  # GET /spaces/create スペース作成
  def new
    @space = Space.new
    @space.private = !Settings.enable_public_space || Settings.default_private_space
  end

  # POST /spaces/create スペース作成(処理)
  # POST /spaces/create(.json) スペース作成API(処理)
  def create
    ActiveRecord::Base.transaction do
      @space.save!
      @current_member = Member.create!(space: @space, user: current_user, power: :admin)
    end
    return redirect_to space_path(@space.code), notice: t('notice.space.create') if format_html?

    set_member_count
    render :show, locals: { notice: t('notice.space.create') }, status: :created
  end

  # GET /spaces/update/:code スペース設定変更
  def edit; end

  # POST /spaces/update/:code スペース設定変更(処理)
  # POST /spaces/update/:code(.json) スペース設定変更API(処理)
  def update
    @space.remove_image! if @space.image_delete
    @space.save!
    return redirect_to space_path(@space.code), notice: t('notice.space.update') if format_html?

    set_member_count
    render :show, locals: { notice: t('notice.space.update') }
  end

  # GET /spaces/delete/:code スペース削除
  def delete; end

  # POST /spaces/delete/:code スペース削除(処理)
  # POST /spaces/delete/:code(.json) スペース削除API(処理)
  def destroy
    @space.set_destroy_reserve!
    return redirect_to space_path(@space.code), notice: t('notice.space.destroy') if format_html?

    set_member_count
    render :show, locals: { notice: t('notice.space.destroy') }
  end

  # GET /spaces/undo_delete/:code スペース削除取り消し
  def undo_delete; end

  # POST /spaces/undo_delete/:code スペース削除取り消し(処理)
  # POST /spaces/undo_delete/:code(.json) スペース削除取り消しAPI(処理)
  def undo_destroy
    @space.set_undo_destroy_reserve!
    return redirect_to space_path(@space.code), notice: t('notice.space.undo_destroy') if format_html?

    set_member_count
    render :show, locals: { notice: t('notice.space.undo_destroy') }
  end

  private

  def redirect_spaces_for_user_destroy_reserved
    redirect_for_user_destroy_reserved(spaces_path)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_space_current_member_auth_private_code
    set_space_current_member_auth_private(params[:code])
  end

  def redirect_space_for_user_destroy_reserved
    redirect_for_user_destroy_reserved(space_path(@space.code))
  end

  def redirect_space_for_space_destroy_reserved
    redirect_to space_path(@space.code), alert: t('alert.space.destroy_reserved') if @space.destroy_reserved?
  end

  def redirect_space_for_not_space_destroy_reserved
    redirect_to space_path(@space.code), alert: t('alert.space.not_destroy_reserved') unless @space.destroy_reserved?
  end

  def response_api_for_not_space_destroy_reserved
    render './failure', locals: { alert: t('alert.space.not_destroy_reserved') }, status: :unprocessable_entity unless @space.destroy_reserved?
  end

  def set_member_count
    @member_count = Member.where(space: @space).count
  end

  def set_params_index
    @text = params[:text]&.slice(..(255 - 1))
    @option = params[:option] == '1'
    @checked = {
      public: params[:public] != '0',
      private: params[:private] != '0',
      join: params[:join] != '0',
      nojoin: params[:nojoin] != '0',
      active: params[:active] != '0',
      destroy: params[:destroy] == '1'
    }
  end

  def validate_params_create
    code = create_unique_code(Space, 'code', "SpacesController.create #{params}", Settings.space_code_length)
    @space = Space.new(space_params(:create).merge(code:, created_user: current_user))
    @space.valid?
    @space.validate_name_uniqueness(current_user) if @space.errors[:name].blank?
    return unless @space.errors.any?
    return render :new, status: :unprocessable_entity if format_html?

    render './failure', locals: { errors: @space.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
  end

  def validate_params_update
    @space.assign_attributes(space_params(:update).merge(last_updated_user: current_user))
    @space.valid?
    @space.validate_name_uniqueness(current_user) if @space.errors[:name].blank? && @space.name_changed?
    return unless @space.errors.any?
    return render :edit, status: :unprocessable_entity if format_html?

    render './failure', locals: { errors: @space.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
  end

  # Only allow a list of trusted parameters through.
  def space_params(target)
    params[:space] = Space.new.attributes if params[:space].blank? # NOTE: 変更なしで成功する為

    params[:space][:name] = params[:space][:name].to_s.gsub(/(^[[:space:]]+)|([[:space:]]+$)/, '') # NOTE: 前後のスペースを削除
    if Settings.enable_public_space
      params[:space][:private] = nil if format_html? && !%w[true false].include?(params[:space][:private]) # NOTE: nilがエラーにならない為
    elsif target == :create
      params[:space][:private] = true
    else
      params[:space][:private] = @space.private
    end
    params[:space][:description] = params[:space][:description]&.gsub(/\R/, "\n") # NOTE: 改行コードを統一

    if target == :create
      params.require(:space).permit(:name, :description, :private, :image)
    else
      params.require(:space).permit(:name, :description, :private, :image, :image_delete)
    end
  end
end
