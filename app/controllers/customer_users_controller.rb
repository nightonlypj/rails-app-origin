class CustomerUsersController < ApplicationController
  before_action :not_found_json_sub_domain_response
  before_action :redirect_base_domain_response
  before_action :authenticate_user!
  before_action :not_found_outside_customer

  # GET /customer_users/:customer_code（ベースドメイン） メンバー一覧
  # GET /customer_users/:customer_code.json（ベースドメイン） メンバー一覧API
  def index
    @customer_users = CustomerUser.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_customer_users_limit'])
                                  .where(customer_id: @customer.id)
                                  .includes(:user)
  end

  # GET /customer_users/new
  def new
    @customer_user = CustomerUser.new
  end

  # GET /customer_users/1/edit
  def edit
    @customer_user = CustomerUser.find(params[:id])
  end

  # POST /customer_users
  # POST /customer_users.json
  def create
    @customer_user = CustomerUser.new(customer_user_params)
    respond_to do |format|
      if @customer_user.save
        format.html { redirect_to @customer_user, notice: 'Customer user was successfully created.' }
        format.json { render :show, status: :created, location: @customer_user }
      else
        format.html { render :new }
        format.json { render json: @customer_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customer_users/1
  # PATCH/PUT /customer_users/1.json
  def update
    @customer_user = CustomerUser.find(params[:id])
    respond_to do |format|
      if @customer_user.update(customer_user_params)
        format.html { redirect_to @customer_user, notice: 'Customer user was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer_user }
      else
        format.html { render :edit }
        format.json { render json: @customer_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customer_users/1
  # DELETE /customer_users/1.json
  def destroy
    @customer_user = CustomerUser.find(params[:id])
    @customer_user.destroy
    respond_to do |format|
      format.html { redirect_to customer_users_url, notice: 'Customer user was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # 所属していない顧客へのアクセス禁止
  def not_found_outside_customer
    @customer = Customer.where(code: params[:customer_code])
                        .includes(:customer_user).where(customer_users: { user_id: current_user.id }).first
    head :not_found if @customer.blank?
  end

  # Only allow a list of trusted parameters through.
  def customer_user_params
    params.require(:customer_user).permit(:customer_id, :user_id, :power)
  end
end
