class CustomersController < ApplicationController
  before_action :not_found_json_sub_domain_response
  before_action :redirect_base_domain_response
  before_action :authenticate_user!
  before_action :not_found_outside_customer, only: %i[show]

  # GET /customers（ベースドメイン） 所属一覧
  # GET /customers.json（ベースドメイン） 所属一覧API
  def index
    @customers = Customer.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_customers_limit'])
                         .includes(:member).where(members: { user_id: current_user.id })
    return if request.format.json? || @customers.current_page <= [@customers.total_pages, 1].max

    redirect_to @customers.total_pages <= 1 ? customers_path : customers_path(page: @customers.total_pages)
  end

  # GET /customers/:customer_code（ベースドメイン） 顧客詳細
  # GET /customers/:customer_code.json（ベースドメイン） 顧客詳細API
  # def show
  # end
end
