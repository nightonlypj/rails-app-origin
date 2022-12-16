class SpacesController < ApplicationAuthController
  before_action :response_not_acceptable_for_not_html, only: %i[new edit delete]
  before_action :authenticate_user!, only: %i[new create edit update delete destroy]
  before_action :redirect_spaces_for_destroy_reserved, only: %i[new create edit update delete destroy], if: :format_html?
  before_action :response_api_for_destroy_reserved, only: %i[create update destroy], unless: :format_html?
  before_action :set_space, only: %i[show edit update delete destroy]
  before_action :check_power, only: %i[edit update delete destroy]
  before_action :set_member_count, only: :show
  before_action :validate_params_create, only: :create
  before_action :validate_params_update, only: :update

  # GET /spaces スペース一覧
  # GET /spaces(.json) スペース一覧API
  def index
    @text = params[:text]&.slice(..(255 - 1))
    @option = params[:option] == '1'
    force_true = !Settings['enable_public_space']
    @checked = {
      public: params[:public] != '0' || force_true,
      private: params[:private] != '0' || force_true,
      join: params[:join] != '0' || force_true,
      nojoin: params[:nojoin] != '0' || force_true,
      active: params[:active] != '0',
      destroy: params[:destroy] == '1'
    }

    @spaces = Space.by_target(current_user, @checked).search(@text)
                   .page(params[:page]).per(Settings['default_spaces_limit']).order(created_at: :desc, id: :desc)
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
  end

  # POST /spaces/create スペース作成(処理)
  # POST /spaces/create(.json) スペース作成API(処理)
  def create
    ActiveRecord::Base.transaction do
      @space.save!
      @current_member = Member.create!(space: @space, user: current_user, power: :admin)
    end

    if format_html?
      redirect_to space_path(@space.code), notice: t('notice.space.create')
    else
      set_member_count
      render :show, locals: { notice: t('notice.space.create') }
    end
  end

  # GET /spaces/:code/update スペース設定変更
  def edit; end

  # POST /spaces/:code/update スペース設定変更(処理)
  # POST /spaces/:code/update(.json) スペース設定変更API(処理)
  def update
    @space.remove_image! if params[:space].present? && params[:space][:image_delete] == '1'
    @space.save!

    if format_html?
      redirect_to space_path(@space.code), notice: t('notice.space.update')
    else
      @current_member = Member.where(space: @space, user: current_user)&.first
      set_member_count
      render :show, locals: { notice: t('notice.space.update') }
    end
  end

  def delete; end

  # DELETE /spaces/1 or /spaces/1.json
  def destroy
    @space.destroy
    respond_to do |format|
      format.html { redirect_to spaces_url, notice: 'Space was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def redirect_spaces_for_destroy_reserved
    redirect_for_destroy_reserved(spaces_path)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_space
    @space = Space.find_by(code: params[:code])
    return response_not_found if @space.blank?
    return authenticate_user! if @space.private && !user_signed_in?

    @current_member = current_user.present? ? Member.where(space: @space, user: current_user)&.first : nil
    response_forbidden if @space.private && @current_member.blank?
  end

  def check_power
    response_forbidden unless @current_member&.power_admin?
  end

  def set_member_count
    @member_count = Member.where(space: @space).count
  end

  def validate_params_create
    code = create_unique_code(Space, 'code', "SpacesController.create #{params}", Settings['space_code_length'])
    @space = Space.new(space_params(:create).merge(code: code, created_user: current_user))
    @space.valid?
    validate_name_uniqueness if @space.errors[:name].blank?

    if @space.errors.any?
      if format_html?
        render :new, status: :unprocessable_entity
      else
        render './failure', locals: { errors: @space.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
      end
    end
  end

  def validate_params_update
    params[:space] = Space.new.attributes if params[:space].blank? # NOTE: パラメータなしの場合に変更されず完了する為

    before_name = @space.name
    @space.assign_attributes(space_params(:update).merge(last_updated_user: current_user))
    @space.valid?
    validate_name_uniqueness if @space.errors[:name].blank? && @space.name != before_name

    if @space.errors.any?
      if format_html?
        render :edit, status: :unprocessable_entity
      else
        render './failure', locals: { errors: @space.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
      end
    end
  end

  def validate_name_uniqueness
    key = 'activerecord.errors.models.space.attributes.name.taken'
    checked = { public: true, private: true, join: true, nojoin: true, active: true, destroy: false } # NOTE: 検索オプションと同じ
    @space.errors.add(:name, t(key)) if Space.by_target(current_user, checked).where(name: @space.name).exists?
  end

  # Only allow a list of trusted parameters through.
  def space_params(target)
    return {} if params[:space].blank?

    params[:space][:name] = params[:space][:name].to_s.gsub(/(^[[:space:]]+)|([[:space:]]+$)/, '') # NOTE: 前後のスペースを削除
    if Settings['enable_public_space']
      params[:space][:private] = nil if format_html? && !%w[true false].include?(params[:space][:private]) # NOTE: nilがエラーにならない為
    else
      params[:space][:private] = true if target == :create
      params[:space][:private] = @space.private if target == :update
    end

    params.require(:space).permit(:name, :description, :private, :image)
  end
end
