class MembersController < ApplicationController
  before_action :not_found_json_sub_domain_response
  before_action :redirect_base_domain_response, only: %i[index new edit delete]
  before_action :not_found_sub_domain_response, only: %i[create update destroy]
  before_action :authenticate_user!
  before_action :not_found_outside_customer
  before_action :not_found_outside_member, only: %i[edit update delete destroy]
  before_action :alert_before_update_power, only: %i[edit update]
  before_action :alert_before_destroy_power, only: %i[delete destroy]

  # GET /members/:customer_code（ベースドメイン） メンバー一覧
  # GET /members/:customer_code.json（ベースドメイン） メンバー一覧API
  def index
    @members = Member.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_members_limit'])
                     .where(customer_id: @customer.id)
                     .includes(:user)
  end

  # GET /members/new
  def new
    @member = Member.new
  end

  # GET /members/:customer_code/:user_code/edit（ベースドメイン） メンバー権限変更
  # def edit
  # end

  # POST /members
  # POST /members.json
  def create
    @member = Member.new(member_params)
    respond_to do |format|
      if @member.save
        format.html { redirect_to @member, notice: 'Customer user was successfully created.' }
        format.json { render :show, status: :created, location: @member }
      else
        format.html { render :new }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /members/:customer_code/:user_code（ベースドメイン） メンバー権限変更(処理)
  # PATCH/PUT /members/:customer_code/:user_code.json（ベースドメイン） メンバー権限変更API
  def update
    # validates :power # Tips: enum未定義の値はvalidatesの前にArgumentErrorやRecordInvalidになる
    if params[:member].blank? || params[:member][:power].blank?
      @member.errors.add(:power, t('activerecord.errors.models.member.attributes.power.blank'))
    elsif Member.powers[params[:member][:power]].blank?
      @member.errors.add(:power, t('activerecord.errors.models.member.attributes.power.invalid'))
    elsif !@customer.member.first.update_power?(params[:member][:power])
      @member.errors.add(:power, t('alert.member.not_update_power.owner'))
    end

    respond_to do |format|
      if @member.errors.blank? && @member.update!(params.require(:member).permit(:power))
        format.html { redirect_to members_path(customer_code: @customer.code), notice: t('notice.member.update') }
        format.json { render json: { status: 'OK', notice: t('notice.member.update') }, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: { status: 'NG', errors: @member.errors }, status: :unprocessable_entity }
      end
    end
  end

  # GET /members/:customer_code/:user_code/delete（ベースドメイン） メンバー解除
  # def delete
  # end

  # DELETE /members/:customer_code/:user_code（ベースドメイン） メンバー解除(処理)
  # DELETE /members/:customer_code/:user_code.json（ベースドメイン） メンバー解除API
  def destroy
    @member.destroy
    respond_to do |format|
      format.html { redirect_to members_url, notice: t('notice.member.destroy') }
      format.json { render json: { status: 'OK', notice: t('notice.member.destroy') }, status: :ok }
    end
  end

  private

  # 存在しない/所属していない顧客へのアクセス禁止
  def not_found_outside_customer
    @customer = Customer.where(code: params[:customer_code])
                        .includes(:member).where(members: { user_id: current_user.id }).first
    return if @customer.present?
    return render json: { error: t('errors.messages.customer_code_error') }, status: :not_found if json_request?

    head :not_found
  end

  # 存在しない/所属していないメンバーへのアクセス禁止
  def not_found_outside_member
    @member = Member.where(customer_id: @customer.id)
                    .includes(:user).where(users: { code: params[:user_code] }).first
    return if @customer.present?
    return render json: { error: t('errors.messages.user_code_error') }, status: :not_found if json_request?

    head :not_found
  end

  # 変更権限がないメンバーへのアクセス禁止
  def alert_before_update_power
    if !@customer.member.first.update_power?(@member.power)
      key = @member.power == 'Owner' ? 'alert.member.not_update_power.owner' : 'alert.member.not_update_power.admin'
    elsif @member.user == current_user
      key = @member.power == 'Owner' ? 'alert.member.own_update_power.owner' : 'alert.member.own_update_power.admin'
    elsif current_user.destroy_reserved?
      key = 'alert.user.destroy_reserved'
    else
      return
    end
    return render json: { error: t(key) }, status: :forbidden if json_request?

    redirect_to members_path(customer_code: params[:customer_code]), alert: t(key)
  end

  # 解除権限がないメンバーへのアクセス禁止
  def alert_before_destroy_power
    if !@customer.member.first.destroy_power?(@member.power)
      key = @member.power == 'Owner' ? 'alert.member.not_destroy_power.owner' : 'alert.member.not_destroy_power.admin'
    elsif @member.user == current_user
      key = @member.power == 'Owner' ? 'alert.member.own_destroy_power.owner' : 'alert.member.own_destroy_power.admin'
    elsif current_user.destroy_reserved?
      key = 'alert.user.destroy_reserved'
    else
      return
    end
    return render json: { error: t(key) }, status: :forbidden if json_request?

    redirect_to members_path(customer_code: params[:customer_code]), alert: t(key)
  end
end
