class CustomerUsersController < ApplicationController
  before_action :set_customer_user, only: %i[show edit update destroy]

  # GET /customer_users
  # GET /customer_users.json
  def index
    @customer_users = CustomerUser.all
  end

  # GET /customer_users/1
  # GET /customer_users/1.json
  def show; end

  # GET /customer_users/new
  def new
    @customer_user = CustomerUser.new
  end

  # GET /customer_users/1/edit
  def edit; end

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
    @customer_user.destroy
    respond_to do |format|
      format.html { redirect_to customer_users_url, notice: 'Customer user was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_customer_user
    @customer_user = CustomerUser.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def customer_user_params
    params.require(:customer_user).permit(:customer_id, :user_id, :power)
  end
end
