class InvitationsController < ApplicationAuthController
  before_action :authenticate_user!
  before_action :set_space, :check_power
  before_action :set_invitation, only: %i[show edit update]

  # GET /invitations/:space_code 招待URL一覧
  # GET /invitations/:space_code(.json) 招待URL一覧API
  def index
    @invitations = Invitation.where(space: @space).page(params[:page]).per(Settings['default_invitations_limit']).order(created_at: :desc, id: :desc)

    if format_html? && @invitations.current_page > [@invitations.total_pages, 1].max
      redirect_to @invitations.total_pages <= 1 ? invitations_path : invitations_path(page: @invitations.total_pages)
    end
  end

  # GET /invitations/1 or /invitations/1.json
  def show; end

  # GET /invitations/new
  def new
    @invitation = Invitation.new
  end

  # GET /invitations/1/edit
  def edit; end

  # POST /invitations or /invitations.json
  def create
    @invitation = Invitation.new(invitation_params)

    respond_to do |format|
      if @invitation.save
        format.html { redirect_to @invitation, notice: 'Invitation was successfully created.' }
        format.json { render :show, status: :created, location: @invitation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @invitation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invitations/1 or /invitations/1.json
  def update
    respond_to do |format|
      if @invitation.update(invitation_params)
        format.html { redirect_to @invitation, notice: 'Invitation was successfully updated.' }
        format.json { render :show, status: :ok, location: @invitation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @invitation.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_space
    @space = Space.find_by(code: params[:space_code])
    return response_not_found if @space.blank?

    @current_member = Member.where(space: @space, user: current_user).eager_load(:user)&.first
    response_forbidden if @current_member.blank?
  end

  def check_power
    response_forbidden unless @current_member.power_admin?
  end

  def set_invitation
    @invitation = Invitation.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def invitation_params
    params.fetch(:invitation, {})
  end
end
