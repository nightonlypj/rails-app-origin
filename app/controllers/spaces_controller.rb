class SpacesController < ApplicationController
  before_action :not_found_json_sub_domain_response, only: %i[index create]
  before_action :redirect_base_domain_response, only: %i[index new]
  before_action :not_found_base_domain_response, only: %i[edit update]
  before_action :not_found_sub_domain_response, only: %i[create]
  before_action :authenticate_user!, only: %i[new edit create update]

  # GET /spaces（ベースドメイン） スペース一覧
  # GET /spaces.json（ベースドメイン） スペース一覧API
  def index
    @spaces = Space.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_spaces_limit'])
    return if request.format.json? || @spaces.current_page <= [@spaces.total_pages, 1].max

    redirect_to @spaces.total_pages <= 1 ? spaces_path : spaces_path(page: @spaces.total_pages)
  end

  # GET /spaces/new（ベースドメイン） スペース作成
  def new
    @customer = Customer.new
    @customer.code = params['customer_code'] if params['customer_code'].present?
    @space = Space.new
    render_new
  end

  # GET /spaces/edit（サブドメイン） スペース情報変更
  def edit
    @space = request_space
    head :not_found if @space.blank?
  end

  # POST /spaces（ベースドメイン） スペース作成(処理)
  # POST /spaces.json（ベースドメイン） スペース作成API
  def create
    @customer = Customer.new(params.require(:space).require(:customer).permit(:code))
    if @customer.code.blank?
      @customer.errors.add(:code, t('errors.messages.customer.code_blank'))
    else
      customer = Customer.where(code: @customer.code)
                         .includes(:member).where(members: { user_id: current_user.id }).first
      if customer.blank?
        @customer.errors.add(:code, t('errors.messages.customer.code_invalid'))
      else
        @customer = customer
      end
    end

    @space = Space.new(params.require(:space).permit(:subdomain, :name).merge(customer_id: @customer.id))
    @space.valid? if @customer.errors.present?
    respond_to do |format|
      if @customer.errors.blank? && @space.save
        format.html { redirect_to "//#{Space.last.subdomain}.#{Settings['base_domain']}", notice: t('notice.space.create') }
        format.json { render :create, status: :created }
      else
        format.html { render_new }
        format.json { render :create, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /spaces（サブドメイン） スペース情報変更(処理)
  # PATCH/PUT /spaces.json（サブドメイン） スペース情報変更API
  def update
    @space = request_space
    return head :not_found if @space.blank?

    respond_to do |format|
      if @space.update(params.require(:space).permit(:subdomain, :name))
        format.html { redirect_to "//#{@space.subdomain}.#{Settings['base_domain']}", notice: t('notice.space.update') }
        format.json { render :update, status: :ok }
      else
        format.html { render :edit }
        format.json { render :update, status: :unprocessable_entity }
      end
    end
  end

  private

  # スペース作成を表示
  def render_new
    @customers = Customer.order(created_at: 'DESC', id: 'DESC')
                         .includes(:member).where(members: { user_id: current_user.id })
    render :new
  end
end
