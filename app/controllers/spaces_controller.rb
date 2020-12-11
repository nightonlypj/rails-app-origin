class SpacesController < ApplicationController
  before_action :not_found_json_sub_domain_response, only: %i[index create]
  before_action :redirect_base_domain_response, only: %i[index new]
  before_action :not_found_base_domain_response, only: %i[edit update]

  # GET /spaces（ベースドメイン） スペース一覧
  # GET /spaces.json（ベースドメイン） スペース一覧API
  def index
    @spaces = Space.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_spaces_limit'])
  end

  # GET /spaces/new（ベースドメイン） スペース作成
  def new
    @space = Space.new
  end

  # GET /spaces/edit（サブドメイン） スペース編集
  def edit
    @space = request_space
    head :not_found if @space.blank?
  end

  # POST /spaces/create（ベースドメイン） スペース登録(処理)
  # POST /spaces/create.json（ベースドメイン） スペース登録API
  def create
    return redirect_to "//#{Settings['base_domain']}#{new_space_path}" unless base_domain_request?

    # TODO: 仮対応
    @space = Space.new(space_params.merge(customer_id: 1))
    respond_to do |format|
      if @space.save
        format.html { redirect_to "//#{Space.last.subdomain}.#{Settings['base_domain']}", notice: t('notice.space.create') }
        format.json { render :create, status: :created }
      else
        format.html { render :new }
        format.json { render :create, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spaces/update（サブドメイン） スペース更新(処理)
  # PATCH/PUT /spaces/update.json（サブドメイン） スペース更新API
  def update
    @space = request_space
    return head :not_found if @space.blank?

    respond_to do |format|
      if @space.update(space_params)
        format.html { redirect_to "//#{@space.subdomain}.#{Settings['base_domain']}", notice: t('notice.space.update') }
        format.json { render :update, status: :ok }
      else
        format.html { render :edit }
        format.json { render :update, status: :unprocessable_entity }
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def space_params
    params.require(:space).permit(:subdomain, :name)
  end
end
