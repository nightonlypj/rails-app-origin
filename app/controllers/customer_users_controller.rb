class CustomerUsersController < ApplicationController
  before_action :not_found_json_sub_domain_response
  before_action :redirect_base_domain_response, only: %i[index new edit delete]
  before_action :not_found_sub_domain_response, only: %i[create update destroy]
  before_action :authenticate_user!
  before_action :not_found_outside_customer
  before_action :not_found_outside_customer_user, only: %i[edit update delete destroy]
  before_action :alert_before_update_power, only: %i[edit update]
  before_action :alert_before_destroy_power, only: %i[delete destroy]

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

  # GET /customer_users/:customer_code/:user_code/edit（ベースドメイン） メンバー権限変更
  # def edit
  # end

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

  # PATCH/PUT /customer_users/:customer_code/:user_code（ベースドメイン） メンバー権限変更(処理)
  # PATCH/PUT /customer_users/:customer_code/:user_code.json（ベースドメイン） メンバー権限変更API
  def update
    # validates :power # Tips: enum未定義の値はvalidatesの前にArgumentErrorやRecordInvalidになる
    if params[:customer_user].blank? || params[:customer_user][:power].blank?
      @customer_user.errors.add(:power, t('activerecord.errors.models.customer_user.attributes.power.blank'))
    elsif CustomerUser.powers[params[:customer_user][:power]].blank?
      @customer_user.errors.add(:power, t('activerecord.errors.models.customer_user.attributes.power.invalid'))
    elsif !@customer.customer_user.first.update_power?(params[:customer_user][:power])
      @customer_user.errors.add(:power, t('alert.customer_user.not_update_power.owner'))
    end

    respond_to do |format|
      if @customer_user.errors.blank? && @customer_user.update!(params.require(:customer_user).permit(:power))
        format.html { redirect_to customer_users_path(customer_code: @customer.code), notice: t('notice.customer_user.update') }
        format.json { render json: { status: 'OK', notice: t('notice.customer_user.update') }, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: { status: 'NG', errors: @customer_user.errors }, status: :unprocessable_entity }
      end
    end
  end

  # GET /customer_users/:customer_code/:user_code/delete（ベースドメイン） メンバー解除
  # def delete
  # end

  # DELETE /customer_users/:customer_code/:user_code（ベースドメイン） メンバー解除(処理)
  # DELETE /customer_users/:customer_code/:user_code.json（ベースドメイン） メンバー解除API
  def destroy
    @customer_user.destroy
    respond_to do |format|
      format.html { redirect_to customer_users_url, notice: t('notice.customer_user.destroy') }
      format.json { render json: { status: 'OK', notice: t('notice.customer_user.destroy') }, status: :ok }
    end
  end

  private

  # 存在しない/所属していない顧客へのアクセス禁止
  def not_found_outside_customer
    @customer = Customer.where(code: params[:customer_code])
                        .includes(:customer_user).where(customer_users: { user_id: current_user.id }).first
    return if @customer.present?
    return render json: { error: t('errors.messages.customer_code_error') }, status: :not_found if json_request?

    head :not_found
  end

  # 存在しない/所属していないメンバーへのアクセス禁止
  def not_found_outside_customer_user
    @customer_user = CustomerUser.where(customer_id: @customer.id)
                                 .includes(:user).where(users: { code: params[:user_code] }).first
    return if @customer.present?
    return render json: { error: t('errors.messages.user_code_error') }, status: :not_found if json_request?

    head :not_found
  end

  # 変更権限がないメンバーへのアクセス禁止
  def alert_before_update_power
    if !@customer.customer_user.first.update_power?(@customer_user.power)
      key = @customer_user.power == 'Owner' ? 'alert.customer_user.not_update_power.owner' : 'alert.customer_user.not_update_power.admin'
    elsif @customer_user.user == current_user
      key = @customer_user.power == 'Owner' ? 'alert.customer_user.own_update_power.owner' : 'alert.customer_user.own_update_power.admin'
    elsif current_user.destroy_reserved?
      key = 'alert.user.destroy_reserved'
    else
      return
    end
    return render json: { error: t(key) }, status: :forbidden if json_request?

    redirect_to customer_users_path(customer_code: params[:customer_code]), alert: t(key)
  end

  # 解除権限がないメンバーへのアクセス禁止
  def alert_before_destroy_power
    if !@customer.customer_user.first.destroy_power?(@customer_user.power)
      key = @customer_user.power == 'Owner' ? 'alert.customer_user.not_destroy_power.owner' : 'alert.customer_user.not_destroy_power.admin'
    elsif @customer_user.user == current_user
      key = @customer_user.power == 'Owner' ? 'alert.customer_user.own_destroy_power.owner' : 'alert.customer_user.own_destroy_power.admin'
    elsif current_user.destroy_reserved?
      key = 'alert.user.destroy_reserved'
    else
      return
    end
    return render json: { error: t(key) }, status: :forbidden if json_request?

    redirect_to customer_users_path(customer_code: params[:customer_code]), alert: t(key)
  end
end
