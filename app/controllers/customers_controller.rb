class CustomersController < ApplicationController
  before_action :redirect_base_domain_response, only: %i[index show edit]
  before_action :not_found_sub_domain_response, only: %i[update]
  before_action :authenticate_user!
  before_action :not_found_outside_customer, only: %i[show edit update]
  before_action :redirect_response_not_update_power, only: %i[edit update]
  before_action :redirect_response_destroy_reserved, only: %i[edit update]

  # GET /customers（ベースドメイン） 顧客一覧
  # GET /customers.json（ベースドメイン） 顧客一覧API
  def index
    @customers = Customer.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_customers_limit'])
                         .eager_load(:member).where(members: { user_id: current_user.id })
    return if request.format.json? || @customers.current_page <= [@customers.total_pages, 1].max

    redirect_to @customers.total_pages <= 1 ? customers_path : customers_path(page: @customers.total_pages)
  end

  # GET /customers/:customer_code（ベースドメイン） 顧客詳細
  # GET /customers/:customer_code.json（ベースドメイン） 顧客詳細API
  # def show
  # end

  # GET /customers/:customer_code/edit（ベースドメイン） 顧客情報変更
  # def edit
  # end

  # PUT(PATCH) /customers/:customer_code/edit（ベースドメイン） 顧客情報変更(処理)
  # PUT(PATCH) /customers/:customer_code/edit.json（ベースドメイン） 顧客情報変更API
  def update
    respond_to do |format|
      if @customer.update(params.require(:customer).permit(:name))
        format.html { redirect_to customer_path, notice: t('notice.customer.update') }
        format.json { render json: { status: 'OK', notice: t('notice.customer.update') }, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: { status: 'NG', error: @customer.errors.messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  # 変更権限がない場合、リダイレクトしてメッセージを表示
  def redirect_response_not_update_power
    return if @customer.member.first.customer_update_power?

    respond_to do |format|
      format.html { redirect_to root_path, alert: t('alert.customer.not_update_power') }
      format.json { render json: { error: t('alert.customer.not_update_power') }, status: :forbidden }
    end
  end
end
