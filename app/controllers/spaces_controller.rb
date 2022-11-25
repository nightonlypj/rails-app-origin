class SpacesController < ApplicationAuthController
  before_action :authenticate_user!, only: %i[new create edit update delete destroy]
  before_action :spaces_redirect_response_destroy_reserved, only: %i[new create edit update delete destroy]
  before_action :set_space, only: %i[show edit update delete destroy]

  # GET /spaces スペース一覧
  # GET /spaces(.json) スペース一覧API
  def index
    @text = params[:text]&.slice(..(255 - 1))
    @option = params[:option] == '1'
    @exclude = params[:exclude] == '1'

    @spaces = Space.by_target(current_user, @exclude).search(@text)
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

  # GET /spaces/1 or /spaces/1.json
  def show; end

  # GET /spaces/new
  def new
    @space = Space.new
  end

  # POST /spaces or /spaces.json
  def create
    @space = Space.new(space_params)

    respond_to do |format|
      if @space.save
        format.html { redirect_to @space, notice: 'Space was successfully created.' }
        format.json { render :show, status: :created, location: @space }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @space.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /spaces/1/edit
  def edit; end

  # PATCH/PUT /spaces/1 or /spaces/1.json
  def update
    respond_to do |format|
      if @space.update(space_params)
        format.html { redirect_to @space, notice: 'Space was successfully updated.' }
        format.json { render :show, status: :ok, location: @space }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @space.errors, status: :unprocessable_entity }
      end
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

  def spaces_redirect_response_destroy_reserved
    redirect_response_destroy_reserved(spaces_path)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_space
    @space = Space.find_by!(code: params[:code])
  end

  # Only allow a list of trusted parameters through.
  def space_params
    params.fetch(:space, {})
  end
end
