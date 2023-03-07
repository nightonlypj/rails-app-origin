class InvitationsController < ApplicationAuthController
  before_action :response_not_acceptable_for_not_api, only: :show
  before_action :response_not_acceptable_for_not_html, only: %i[new edit]
  before_action :authenticate_user!
  before_action :set_space_current_member
  before_action :redirect_invitations_for_user_destroy_reserved, only: %i[new create edit update], if: :format_html?
  before_action :response_api_for_user_destroy_reserved, only: %i[create update], unless: :format_html?
  before_action :check_power
  before_action :set_invitation, only: %i[show edit update]
  before_action :check_email_joined, only: %i[edit update]
  before_action :validate_params_create, only: :create
  before_action :validate_params_update, only: :update

  # GET /invitations/:space_code 招待URL一覧
  # GET /invitations/:space_code(.json) 招待URL一覧API
  def index
    @invitations = Invitation.where(space: @space).order(created_at: :desc, id: :desc)
                             .page(params[:page]).per(Settings.default_invitations_limit)

    if format_html? && @invitations.current_page > [@invitations.total_pages, 1].max
      redirect_to @invitations.total_pages <= 1 ? invitations_path : invitations_path(page: @invitations.total_pages)
    end
  end

  # GET /invitations/:space_code/detail/:code(.json) 招待URL詳細API
  def show; end

  # GET /invitations/:space_code/create 招待URL作成
  def new
    @invitation = Invitation.new(ended_time: '23:59')
  end

  # POST /invitations/:space_code/create 招待URL作成(処理)
  # POST /invitations/:space_code/create(.json) 招待URL作成API(処理)
  def create
    @invitation.domains = @domains
    @invitation.ended_at = @invitation.new_ended_at
    @invitation.save!

    if format_html?
      redirect_to invitations_path(@space.code), notice: t('notice.invitation.create')
    else
      render :show, locals: { notice: t('notice.invitation.create') }, status: :created
    end
  end

  # GET /invitations/:space_code/update/:code 招待URL設定変更
  def edit; end

  # POST /invitations/:space_code/update/:code 招待URL設定変更API(処理)
  # POST /invitations/:space_code/update/:code(.json) 招待URL設定変更API(処理)
  def update
    @invitation.ended_at = @invitation.new_ended_at
    if %w[1 true].include?(@invitation.delete.to_s) && @invitation.destroy_schedule_at.blank?
      @invitation.destroy_requested_at = Time.current
      @invitation.destroy_schedule_at  = Time.current + Settings.invitation_destroy_schedule_days.days
    end
    if %w[1 true].include?(@invitation.undo_delete.to_s) && @invitation.destroy_schedule_at.present?
      @invitation.destroy_requested_at = nil
      @invitation.destroy_schedule_at  = nil
    end
    @invitation.save!

    if format_html?
      redirect_to invitations_path(@space.code), notice: t('notice.invitation.update')
    else
      render :show, locals: { notice: t('notice.invitation.update') }
    end
  end

  private

  def redirect_invitations_for_user_destroy_reserved
    redirect_for_user_destroy_reserved(invitations_path(@space.code))
  end

  # Use callbacks to share common setup or constraints between actions.
  def check_power
    response_forbidden unless @current_member.power_admin?
  end

  def set_invitation
    @invitation = Invitation.where(space: @space, code: params[:code]).first
    return response_not_found if @invitation.blank?

    if @invitation.ended_at.present?
      @invitation.ended_date = @invitation.ended_at.strftime('%Y/%m/%d')
      @invitation.ended_time = @invitation.ended_at.strftime('%H:%M')
    end
  end

  def check_email_joined
    return if @invitation.email_joined_at.blank?

    if format_html?
      redirect_to invitations_path(@space.code), alert: t('alert.invitation.email_joined')
    else
      render './failure', locals: { alert: t('alert.invitation.email_joined') }, status: :unprocessable_entity
    end
  end

  def validate_params_create
    code = create_unique_code(Invitation, 'code', "InvitationsController.create #{params}")
    @invitation = Invitation.new(invitation_params(:create).merge(space: @space, code: code, created_user: current_user))
    @invitation.valid?
    validate_domains
    return unless @invitation.errors.any?

    if format_html?
      render :new, status: :unprocessable_entity
    else
      render './failure', locals: { errors: @invitation.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
    end
  end

  def validate_domains
    @domains = []
    invalid_domain = nil
    @invitation.domains&.split(/\R/)&.each do |domain|
      domain.strip!
      if domain.present? && !@domains.include?(domain)
        @domains.push(domain)
        break if @domains.count > Settings.invitation_domains_max_count

        invalid_domain = domain if invalid_domain.blank? && !Devise.email_regexp.match?("test@#{domain}")
      end
    end

    if @domains.blank?
      @invitation.errors.add(:domains, :blank)
    elsif @domains.count > Settings.invitation_domains_max_count
      count = Settings.invitation_domains_max_count.to_s(:delimited)
      @invitation.errors.add(:domains, t('activerecord.errors.models.invitation.attributes.domains.max_count', count: count))
    elsif invalid_domain.present?
      @invitation.errors.add(:domains, t('activerecord.errors.models.invitation.attributes.domains.invalid', domain: invalid_domain))
    end
  end

  def validate_params_update
    @invitation.assign_attributes(invitation_params(:update).merge(last_updated_user: current_user))
    return if @invitation.valid?

    if format_html?
      render :edit, status: :unprocessable_entity
    else
      render './failure', locals: { errors: @invitation.errors, alert: t('errors.messages.not_saved.other') }, status: :unprocessable_entity
    end
  end

  # Only allow a list of trusted parameters through.
  def invitation_params(target)
    params[:invitation] = Invitation.new.attributes if params[:invitation].blank? # NOTE: 変更なしで成功する為

    if target == :create
      params[:invitation][:power] = nil if Invitation.powers[params[:invitation][:power]].blank? # NOTE: ArgumentError対策

      params.require(:invitation).permit(:domains, :power, :memo, :ended_date, :ended_time, :ended_zone)
    else
      params.require(:invitation).permit(:memo, :ended_date, :ended_time, :ended_zone, :delete, :undo_delete)
    end
  end
end
