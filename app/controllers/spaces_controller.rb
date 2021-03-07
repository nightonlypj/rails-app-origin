class SpacesController < ApplicationController
  before_action :not_found_json_base_domain_response, only: %i[update]
  before_action :not_found_base_domain_response, only: %i[edit update image_update image_destroy]
  before_action :not_found_json_sub_domain_response, only: %i[index index_public create]
  before_action :redirect_base_domain_response, only: %i[index index_public new]
  before_action :not_found_sub_domain_response, only: %i[create]
  before_action :not_found_request_space_blank, only: %i[edit update image_update image_destroy]
  before_action :authenticate_user!, only: %i[index new edit create update image_update image_destroy]
  before_action :redirect_response_not_update_power, only: %i[edit update image_update image_destroy]
  before_action :redirect_response_destroy_reserved, only: %i[new edit create update image_update image_destroy]
  before_action :set_join_customers, only: %i[new]

  # GET /spaces（ベースドメイン） 参加スペース一覧
  # GET /spaces.json（ベースドメイン） 参加スペース一覧API
  def index
    @spaces = Space.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_spaces_limit'])
                   .eager_load(customer: :member).where(members: { user_id: current_user.id })
    return if request.format.json? || @spaces.current_page <= [@spaces.total_pages, 1].max

    redirect_to @spaces.total_pages <= 1 ? spaces_path : spaces_path(page: @spaces.total_pages)
  end

  # GET /spaces/public（ベースドメイン） 公開スペース一覧
  # GET /spaces/public.json（ベースドメイン） 公開スペース一覧API
  def index_public
    @spaces = Space.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_spaces_limit'])
                   .where(public_flag: true)
    return if request.format.json? || @spaces.current_page <= [@spaces.total_pages, 1].max

    redirect_to @spaces.total_pages <= 1 ? public_spaces_path : public_spaces_path(page: @spaces.total_pages)
  end

  # GET /spaces/new（ベースドメイン） スペース作成
  def new
    @customer = Customer.new
    @customer.create_flag = @join_customers.blank? ? 'true' : 'false'
    @customer.code = params['customer_code'] if params['customer_code'].present?
    @space = Space.new
  end

  # GET /spaces/edit（サブドメイン） スペース情報変更
  def edit
    @space = Space.find(@request_space.id)
    head :not_found if @space.blank?
  end

  # POST /spaces/new（ベースドメイン） スペース作成(処理)
  # POST /spaces/new.json（ベースドメイン） スペース作成API
  def create
    @customer = Customer.new(params.require(:space).require(:customer).permit(:create_flag, :code, :name))
    case @customer.create_flag
    when 'true' # 新規作成
      @customer.code = create_unique_code(Customer, 'code', "SpacesController.create #{params[:space]}", :crc32)
      @customer.valid?
      if @customer.errors.messages[:code].present? # Tips: ユニークコード生成失敗時のメッセージ表示場所変更
        flash[:alert] = @customer.errors.messages[:code].first
        @customer.errors.messages.delete(:code)
        @customer.code = nil
      end
    when 'false' # 選択
      @customer.name = nil # Tips: 新規作成用の項目の為
      if @customer.valid?
        customer = Customer.where(code: @customer.code)
                           .eager_load(:member).where(members: { user_id: current_user.id }).first
        if customer.blank?
          @customer.errors.add(:code, t('errors.messages.customer.code_invalid'))
        elsif !customer.member.first.create_power?
          @customer.errors.add(:code, t('errors.messages.customer.not_create_power'))
        else
          @customer.id = customer.id
        end
      end
    else # 未選択 or 不正値
      @customer.errors.add(:create_flag, t('errors.messages.customer.create_flag_blank'))
    end

    @space = Space.new(params.require(:space).permit(:subdomain, :image, :name, :purpose, :public_flag))
    @space.valid?
    @space.errors.messages.delete(:customer) # Tips: トランザクション範囲を狭くする為

    if @space.errors.any? || @customer.errors.any?
      respond_to do |format|
        format.html do
          set_join_customers
          return render :new
        end
        format.json do
          messages = @customer.errors.any? ? @space.errors.messages.merge({ customer: @customer.errors.messages }) : @space.errors.messages
          return render json: { status: 'NG', error: messages }, status: :unprocessable_entity
        end
      end
    end

    ActiveRecord::Base.transaction do
      if @customer.create_flag == 'true' # 新規作成
        @customer.save!
        Member.new(customer_id: @customer.id, user_id: current_user.id, power: :Owner).save!
      end
      @space.customer_id = @customer.id
      @space.save!
    end
    respond_to do |format|
      format.html { redirect_to "//#{@space.subdomain}.#{Settings['base_domain']}", notice: t('notice.space.create') }
      format.json { render json: { status: 'OK', notice: t('notice.space.create') }, status: :ok }
    end
  end

  # PUT(PATCH) /spaces/edit（サブドメイン） スペース情報変更(処理)
  # PUT(PATCH) /spaces/edit.json（サブドメイン） スペース情報変更API
  def update
    @space = Space.find(@request_space.id)
    return head :not_found if @space.blank?

    respond_to do |format|
      if @space.update(params.require(:space).permit(:subdomain, :name, :purpose, :public_flag))
        format.html { redirect_to "//#{@space.subdomain}.#{Settings['base_domain']}", notice: t('notice.space.update') }
        format.json { render json: { status: 'OK', notice: t('notice.space.update') }, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: { status: 'NG', error: @space.errors.messages }, status: :unprocessable_entity }
      end
    end
  end

  # PUT(PATCH) /spaces/image 画像変更(処理)
  def image_update
    @space = Space.find(@request_space.id)
    if params.blank? || params[:space].blank?
      @space.errors.add(:image, t('errors.messages.image_update_blank'))
      return render :edit
    end

    if @space.update(params.require(:space).permit(:image))
      redirect_to edit_space_path, notice: t('notice.space.image_update')
    else
      render :edit
    end
  end

  # DELETE /spaces/image 画像削除(処理)
  def image_destroy
    @space = Space.find(@request_space.id)
    @space.remove_image!
    if @space.save
      redirect_to edit_space_path, notice: t('notice.space.image_destroy')
    else
      redirect_to edit_space_path, alert: t('alert.space.image_destroy_error')
    end
  end

  private

  # 存在しないサブドメインへのアクセス禁止
  def not_found_request_space_blank
    head :not_found if @request_space.blank?
  end

  # 変更権限がない場合、リダイレクトしてメッセージを表示
  def redirect_response_not_update_power
    member = Member.where(customer_id: @request_space.customer_id, user_id: current_user.id).first
    return head :not_found if member.blank?
    return if member.update_power?

    if request.format.json?
      render json: { error: t('alert.space.not_update_power') }, status: :forbidden
    else
      redirect_to root_path, alert: t('alert.space.not_update_power')
    end
  end

  # 所属顧客を取得
  def set_join_customers
    @join_customers = Customer.order(created_at: 'DESC', id: 'DESC')
                              .eager_load(:member).where(members: { user_id: current_user.id })
  end
end
