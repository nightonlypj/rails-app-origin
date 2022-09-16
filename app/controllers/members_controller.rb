class MembersController < ApplicationAuthController
  before_action :authenticate_user!
  before_action :set_space
  before_action :set_member, only: %i[show edit update destroy]

  # GET /members/:code メンバー一覧
  # GET /members/:code(.json) メンバー一覧API
  def index
    @text = params[:text]&.slice(..(255 - 1))
    @option = params[:option] == '1'
    @power = {}
    Member.powers.each do |key, value|
      @power[value] = true if params[key] != '0'
    end

    @members = Member.where(space: @space, power: @power.keys).search(@text, @current_member).eager_load(:user, :invitation_user)
                     .page(params[:page]).per(Settings['default_members_limit']).order(invitationed_at: :desc, id: :desc)

    if format_html? && @members.current_page > [@members.total_pages, 1].max
      redirect_to @members.total_pages <= 1 ? members_path : members_path(page: @members.total_pages)
    end
  end

  # GET /members/1 or /members/1.json
  def show; end

  # GET /members/new
  def new
    @member = Member.new
  end

  # GET /members/1/edit
  def edit; end

  # POST /members or /members.json
  def create
    @member = Member.new(member_params)

    respond_to do |format|
      if @member.save
        format.html { redirect_to @member, notice: 'Member was successfully created.' }
        format.json { render :show, status: :created, location: @member }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /members/1 or /members/1.json
  def update
    respond_to do |format|
      if @member.update(member_params)
        format.html { redirect_to @member, notice: 'Member was successfully updated.' }
        format.json { render :show, status: :ok, location: @member }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /members/1 or /members/1.json
  def destroy
    @member.destroy
    respond_to do |format|
      format.html { redirect_to members_url, notice: 'Member was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_space
    @space = Space.find_by(code: params[:code])
    return head :not_found if @space.blank?

    @current_member = Member.where(space: @space, user: current_user)&.first
    return head :forbidden if @current_member.blank?
  end

  def set_member
    @member = Member.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def member_params
    params.require(:member).permit(:member_id, :user_id)
  end
end
