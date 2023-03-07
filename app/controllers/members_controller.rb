class MembersController < ApplicationAuthController
  include MembersConcern
  before_action :response_not_acceptable_for_not_api, only: :show
  before_action :response_not_acceptable_for_not_html, only: %i[new result edit]
  before_action :authenticate_user!
  before_action :set_space_current_member
  before_action :redirect_members_for_user_destroy_reserved, only: %i[new create result edit update destroy], if: :format_html?
  before_action :response_api_for_user_destroy_reserved, only: %i[create update destroy], unless: :format_html?
  before_action :check_power, only: %i[new create result edit update destroy]
  before_action :set_member, only: %i[show edit update]
  before_action :check_current_member, only: %i[edit update]
  before_action :set_params_index, only: :index
  before_action :validate_params_create, only: :create
  before_action :set_params_destroy, :validate_params_destroy, only: :destroy

  # GET /members/:space_code メンバー一覧
  # GET /members/:space_code(.json) メンバー一覧API
  def index
    @members = members_search.page(params[:page]).per(Settings.default_members_limit)

    if format_html? && @members.current_page > [@members.total_pages, 1].max
      redirect_to @members.total_pages <= 1 ? members_path : members_path(page: @members.total_pages)
    end
  end

  # GET /members/:space_code/detail/:user_code(.json) メンバー詳細API
  def show; end

  # GET /members/:space_code/create メンバー招待
  def new
    @member = Member.new
  end

  # POST /members/:space_code/create メンバー招待(処理)
  # POST /members/:space_code/create(.json) メンバー招待API(処理)
  def create
    insert_datas = []
    users = User.where(email: @emails)
    exist_users = User.joins(:members).where(members: { space: @space, user: users })
    create_users = users - exist_users
    create_users.each do |user|
      insert_datas.push(@member.attributes.symbolize_keys.merge(user_id: user.id))
    end
    Member.insert_all!(insert_datas) if insert_datas.present?

    @exist_user_mails = exist_users.pluck(:email)
    @create_user_mails = create_users.pluck(:email)
    if format_html?
      redirect_to result_member_path(@space.code), notice: t('notice.member.create'), flash: {
        emails: @emails, exist_user_mails: @exist_user_mails, create_user_mails: @create_user_mails,
        power: @member.power
      }
    else
      @user_codes = users.pluck(:code)
      render :result, locals: { notice: t('notice.member.create') }, status: :created
    end
  end

  # GET /members/:space_code/result メンバー招待（結果）
  def result
    redirect_to members_path(@space.code) if flash.blank?
  end

  # GET /members/:space_code/update/:user_code メンバー情報変更
  def edit; end

  # POST /members/:space_code/update/:user_code メンバー情報変更(処理)
  # POST /members/:space_code/update/:user_code(.json) メンバー情報変更API(処理)
  def update
    unless @member.update(member_params(:update).merge(last_updated_user: current_user))
      if format_html?
        return render :edit, status: :unprocessable_entity
      else
        return render './failure', locals: { errors: @member.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
      end
    end

    if format_html?
      redirect_to members_path(@space.code, active: @member.user.code), notice: t('notice.member.update')
    else
      render :show, locals: { notice: t('notice.member.update') }
    end
  end

  # POST /members/:space_code/delete メンバー削除(処理)
  # POST /members/:space_code/delete(.json) メンバー削除API(処理)
  def destroy
    if @include_myself
      key = 'destroy_include_myself'
    elsif @codes.count != @members.count
      key = 'destroy_include_notfound'
    else
      key = 'destroy'
    end
    @destroy_count = @members.count
    notice = t("notice.member.#{key}", count: @codes.count.to_s(:delimited), destroy_count: @destroy_count.to_s(:delimited))

    @members.destroy_all
    if format_html?
      redirect_to members_path(@space.code), notice: notice
    else
      render locals: { notice: notice }
    end
  end

  private

  def redirect_members_for_user_destroy_reserved
    redirect_for_user_destroy_reserved(members_path(@space.code))
  end

  # Use callbacks to share common setup or constraints between actions.
  def check_power
    response_forbidden unless @current_member.power_admin?
  end

  def set_member
    @member = Member.where(space: @space).joins(:user).where(user: { code: params[:user_code] }).first
    response_not_found if @member.blank?
  end

  def check_current_member
    response_forbidden if @member == @current_member
  end

  def validate_params_create
    now = Time.current
    @member = Member.new(member_params(:create).merge(space: @space, user: current_user, invitationed_user: current_user, invitationed_at: now,
                                                      created_at: now, updated_at: now))
    @member.valid?
    validate_emails
    return unless @member.errors.any?

    if format_html?
      render :new, status: :unprocessable_entity
    else
      render './failure', locals: { errors: @member.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
    end
  end

  def validate_emails
    @emails = []
    invalid_email = nil
    @member.emails&.split(/\R/)&.each do |email|
      email.strip!
      if email.present? && !@emails.include?(email)
        @emails.push(email)
        break if @emails.count > Settings.member_emails_max_count

        invalid_email = email if invalid_email.blank? && !Devise.email_regexp.match?(email)
      end
    end

    if @emails.blank?
      @member.errors.add(:emails, :blank)
    elsif @emails.count > Settings.member_emails_max_count
      error = t('activerecord.errors.models.member.attributes.emails.max_count', count: Settings.member_emails_max_count)
      @member.errors.add(:emails, error)
    elsif invalid_email.present?
      @member.errors.add(:emails, t('activerecord.errors.models.member.attributes.emails.invalid', email: invalid_email))
    end
  end

  def set_params_destroy
    if params[:codes].instance_of?(Array)
      @codes = params[:codes].reject(&:empty?).compact.uniq
    elsif params[:codes].present?
      @codes = params[:codes].to_unsafe_h.map { |code, value| code if value == '1' }.compact.uniq
    else
      @codes = []
    end
    @include_myself = @codes.include?(@current_member.user.code)
  end

  def validate_params_destroy
    alert = nil
    alert = 'alert.member.destroy.codes.blank' if @codes.blank?
    alert = 'alert.member.destroy.codes.myself' if @codes.count == 1 && @include_myself
    if alert.blank?
      delete_codes = @include_myself ? @codes.reject { |key| key == @current_member.user.code } : @codes
      @members = Member.where(space: @space).joins(:user).where(user: { code: delete_codes })
      alert = 'alert.member.destroy.codes.notfound' if @members.empty?
    end
    return if alert.blank?

    if format_html?
      redirect_to members_path, alert: t(alert)
    else
      render './failure', locals: { alert: t(alert) }, status: :unprocessable_entity
    end
  end

  # Only allow a list of trusted parameters through.
  def member_params(target)
    params[:member] = Member.new.attributes if params[:member].blank? # NOTE: 変更なしで成功する為
    params[:member][:power] = nil if Member.powers[params[:member][:power]].blank? # NOTE: ArgumentError対策

    if target == :create
      params.require(:member).permit(:emails, :power)
    else
      params.require(:member).permit(:power)
    end
  end
end
