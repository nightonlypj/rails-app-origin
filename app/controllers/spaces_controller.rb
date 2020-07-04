class SpacesController < ApplicationController
  before_action :set_space, only: %i[edit update]

  # GET /spaces（ベースドメイン） スペース一覧
  # GET /spaces.json（ベースドメイン） スペース一覧API
  def index
    return head :not_found if json_request? && !base_domain_request?
    return redirect_to "//#{Settings['base_domain_link']}#{spaces_path}" unless base_domain_request?

    @spaces = Space.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_spaces_limit'])
  end

  # GET /spaces/new（ベースドメイン） スペース作成
  def new
    return redirect_to "//#{Settings['base_domain_link']}#{new_space_path}" unless base_domain_request?

    @space = Space.new
  end

  # GET /spaces/1/edit
  def edit; end

  # POST /spaces（ベースドメイン） スペース作成(処理)
  # POST /spaces.json（ベースドメイン） スペース作成処理API
  def create
    return head :not_found if json_request? && !base_domain_request?
    return redirect_to "//#{Settings['base_domain_link']}#{new_space_path}" unless base_domain_request?

    @space = Space.new(space_params)
    respond_to do |format|
      if @space.save
        format.html { redirect_to "//#{Space.last.subdomain}.#{Settings['base_domain_link']}", notice: t('notice.space.create') }
        format.json { render :create, status: :created }
      else
        format.html { render :new }
        format.json { render :create, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spaces/1
  # PATCH/PUT /spaces/1.json
  def update
    respond_to do |format|
      if @space.update(space_params)
        format.html { redirect_to @space, notice: 'Space was successfully updated.' }
        format.json { render :show, status: :ok, location: @space }
      else
        format.html { render :edit }
        format.json { render json: @space.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_space
    @space = Space.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def space_params
    params.require(:space).permit(:subdomain, :name)
  end
end
