class MembersController < ApplicationAuthController
  include MembersConcern
  before_action :authenticate_user!
  before_action :set_space
  before_action :members_redirect_response_destroy_reserved, only: %i[new create result edit update destroy]
  before_action :check_power, only: %i[new create result edit update destroy]
  before_action :set_member, only: %i[edit update]
  before_action :set_params_index, only: :index
  before_action :set_params_create, :validate_params_create, only: :create
  before_action :set_params_destroy, :validate_params_destroy, only: :destroy

  # GET /members/:code メンバー一覧
  # GET /members/:code(.json) メンバー一覧API
  def index
    @members = members_search.page(params[:page]).per(Settings['default_members_limit'])

    if format_html? && @members.current_page > [@members.total_pages, 1].max
      redirect_to @members.total_pages <= 1 ? members_path : members_path(page: @members.total_pages)
    end
  end

  # GET /members/:code/create メンバー招待
  def new
    @member = Member.new
  end

  # POST /members/:code/create メンバー招待(処理)
  # POST /members/:code/create(.json) メンバー招待API(処理)
  def create
    insert_datas = []
    users = User.where(email: @emails)
    exist_users = User.joins(:members).where(members: { space: @space, user: users })
    @exist_user_mails = exist_users.pluck(:email)
    @create_user_mails = (users - exist_users).pluck(:email)
    (users - exist_users).each do |user|
      insert_datas.push(@member.attributes.merge({ user_id: user.id, created_at: @member.invitationed_at, updated_at: @member.invitationed_at }))
    end
    Member.insert_all!(insert_datas) if insert_datas.present?

    if format_html?
      redirect_to result_member_path(@space.code), notice: t('notice.member.create'), flash: {
        emails: @emails, exist_user_mails: @exist_user_mails, create_user_mails: @create_user_mails,
        power: @member.power
      }
    else
      render :result, locals: { notice: t('notice.member.create') }, status: :created
    end
  end

  # GET /members/:code/result メンバー招待（結果）
  def result
    redirect_to members_path(@space.code) if flash[:emails].blank?
  end

  # GET /members/:code/update/:user_code メンバー情報変更
  def edit; end

  # POST /members/:code/update/:user_code メンバー情報変更(処理)
  # POST /members/:code/update/:user_code(.json) メンバー情報変更API(処理)
  def update
    unless @member.update(member_params)
      if format_html?
        return render :edit, status: :unprocessable_entity
      else
        return render './failure', locals: { errors: @member.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
      end
    end

    if format_html?
      redirect_to members_path(@space.code), notice: t('notice.member.update')
    else
      render locals: { notice: t('notice.member.update') }
    end
  end

  # POST /members/:code/delete メンバー削除(処理)
  # POST /members/:code/delete(.json) メンバー削除API(処理)
  def destroy
    if @include_myself
      key = 'destroy_include_myself'
    elsif @codes.count != @members.count
      key = 'destroy_notfound'
    else
      key = 'destroy'
    end
    notice = t("notice.member.#{key}").gsub(/%{count}/, @codes.count.to_s(:delimited)).gsub(/%{destroy_count}/, @members.count.to_s(:delimited))

    @members.destroy_all
    if format_html?
      redirect_to members_path(@space.code), notice: notice
    else
      render locals: { notice: notice }
    end
  end

  private

  def members_redirect_response_destroy_reserved
    redirect_response_destroy_reserved(members_path(@space.code))
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_space
    @space = Space.find_by(code: params[:code])
    return head :not_found if @space.blank?

    @current_member = Member.where(space: @space, user: current_user).eager_load(:user)&.first
    head :forbidden if @current_member.blank?
  end

  def check_power
    head :forbidden unless @current_member.power_admin?
  end

  def set_member
    @member = Member.where(space: @space).joins(:user).where(user: { code: params[:user_code] })&.first
    return head :not_found if @member.blank?

    head :forbidden if @member == @current_member
  end

  def set_params_create
    @emails = []
    params[:member][:emails]&.split(/\R/)&.each do |email|
      email.strip!
      @emails.push(email) if email.present? && !@emails.include?(email)
    end
  end

  def validate_params_create
    @member = Member.new(member_params.merge(space: @space, user: current_user, invitation_user: current_user, invitationed_at: Time.current))
    @member.valid?

    if @emails.blank?
      @member.errors.add(:emails, :blank)
    elsif @emails.count > Settings['create_members_max_count']
      error = t('activerecord.errors.models.member.attributes.emails.max_count').gsub(/%{count}/, Settings['create_members_max_count'].to_s)
      @member.errors.add(:emails, error)
    end

    if @member.errors.any?
      if format_html?
        @member.emails = params[:member][:emails]
        render :new, status: :unprocessable_entity
      else
        render './failure', locals: { errors: @member.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
      end
    end
  end

  def set_params_destroy
    if params[:codes].instance_of?(Array)
      @codes = params[:codes].uniq.compact
    else
      @codes = params[:codes].to_unsafe_h.map { |code, value| code if value == '1' }.uniq.compact
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

    if alert.present?
      if format_html?
        redirect_to members_path, alert: t(alert)
      else
        render './failure', locals: { alert: t(alert) }, status: :unprocessable_entity
      end
    end
  end

  # Only allow a list of trusted parameters through.
  def member_params
    # ArgumentError対策
    params[:member][:power] = nil if Member.powers[params[:member][:power]].blank?

    params.require(:member).permit(:power)
  end
end
