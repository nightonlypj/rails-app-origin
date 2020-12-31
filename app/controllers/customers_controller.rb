class CustomersController < ApplicationController
  before_action :not_found_json_sub_domain_response
  before_action :redirect_base_domain_response
  before_action :authenticate_user!

  # GET /customers（ベースドメイン） 所属一覧
  # GET /customers.json（ベースドメイン） 所属一覧API
  def index
    @customers = Customer.order(created_at: 'ASC', id: 'ASC').page(params[:page]).per(Settings['default_customers_limit'])
                         .includes(:member).where(members: { user_id: current_user.id })
  end
end
