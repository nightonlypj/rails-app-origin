class MembersController < ApplicationController
  before_action :not_found_json_sub_domain_response
  before_action :redirect_base_domain_response, only: %i[index new edit delete]
  before_action :not_found_sub_domain_response, only: %i[create update destroy]
  before_action :authenticate_user!
  before_action :not_found_outside_customer
  before_action :not_found_outside_member, only: %i[edit update delete destroy]
  before_action :alert_before_create_power, only: %i[new create]
  before_action :alert_before_update_power, only: %i[edit update]
  before_action :alert_before_destroy_power, only: %i[delete destroy]

  # GET /members/:customer_code（ベースドメイン） メンバー一覧
  # GET /members/:customer_code.json（ベースドメイン） メンバー一覧API
  def index
    @members = Member.order(created_at: 'DESC', id: 'DESC').page(params[:page]).per(Settings['default_members_limit'])
                     .where(customer_id: @customer.id)
                     .eager_load(:user)
    return if request.format.json? || @members.current_page <= [@members.total_pages, 1].max

    if @members.total_pages <= 1
      redirect_to members_path(customer_code: @customer.code)
    else
      redirect_to members_path(customer_code: @customer.code, page: @members.total_pages)
    end
  end

  # GET /members/:customer_code/new（ベースドメイン） メンバー招待
  def new
    @member = Member.new
    @user = User.new
  end

  # GET /members/:customer_code/:user_code/edit（ベースドメイン） メンバー権限変更
  # def edit
  # end

  # POST /members/:customer_code（ベースドメイン） メンバー招待(処理)
  # POST /members/:customer_code.json（ベースドメイン） メンバー招待API
  def create
    @member = Member.new
    @user = User.new(params.require(:member).require(:user).permit(:email))
    exist_user = @user.email.present? ? User.find_by(email: @user.email) : nil
    invitationed_at = Time.current
    # validates :power # Tips: enum未定義の値はvalidatesの前にArgumentErrorやRecordInvalidになる
    if params[:member].blank? || params[:member][:power].blank?
      @member.errors.add(:power, t('activerecord.errors.models.member.attributes.power.blank'))
    elsif Member.powers[params[:member][:power]].blank?
      @member.errors.add(:power, t('activerecord.errors.models.member.attributes.power.invalid'))
    else
      @member.assign_attributes(params.require(:member).permit(:power))
      @member.errors.add(:power, t('alert.member.not_create_power.owner')) unless @customer.member.first.create_power?(@member.power)
    end
    if exist_user.present?
      exist_member = Member.find_by(customer_id: @customer.id, user_id: exist_user.id)
      @user.errors.add(:email, t('activerecord.errors.models.member.attributes.user.taken')) if exist_member.present?
    end
    # validates :email # Tips: emailとpowerのメッセージを同時に出す為
    if exist_user.blank?
      code = create_unique_code(User, 'code', "MembersController.create[code] #{params[:member]}")
      password = Faker::Internet.password(min_length: 8) # Tips: ダミーを設定。nameも同様
      invitation_token = create_unique_code(User, 'invitation_token', "MembersController.create[invitation_token] #{params[:member]}")
      @user.assign_attributes(code: code, name: '-', password: password, confirmed_at: '0000-01-01 00:00:00+0000',
                              invitation_customer_id: @customer.id, invitation_token: invitation_token, invitation_requested_at: invitationed_at)
      @user.valid?
    end
    if @member.errors.any? || @user.errors.any?
      respond_to do |format|
        format.html { return render :new }
        format.json do
          messages = @user.errors.any? ? @member.errors.messages.merge({ user: @user.errors.messages }) : @member.errors.messages
          return render json: { status: 'NG', error: messages }, status: :unprocessable_entity
        end
      end
    end

    ActiveRecord::Base.transaction do
      @user.save! if exist_user.blank?
      user_id = exist_user.present? ? exist_user.id : @user.id
      @member.assign_attributes(customer_id: @customer.id, user_id: user_id, invitation_user_id: current_user.id, invitationed_at: invitationed_at)
      @member.save!
      Infomation.new(started_at: invitationed_at, target: :User, user_id: @member.user_id,
                     action: 'MemberCreate', action_user_id: current_user.id, customer_id: @customer.id).save!
      UserMailer.with(user: @user, member: @member, customer: @customer, current_user: current_user).member_create.deliver_now if exist_user.blank?
    end
    respond_to do |format|
      format.html { redirect_to members_path(customer_code: @customer.code), notice: t('notice.member.create') }
      format.json { render json: { status: 'OK', notice: t('notice.member.create') }, status: :ok }
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
    else
      before_power = @member.power
      @member.assign_attributes(params.require(:member).permit(:power))
      @member.errors.add(:power, t('alert.member.not_update_power.owner')) unless @customer.member.first.update_power?(@member.power)
    end
    if @member.errors.any?
      respond_to do |format|
        format.html { return render :edit }
        format.json { return render json: { status: 'NG', error: @member.errors.messages }, status: :unprocessable_entity }
      end
    end

    ActiveRecord::Base.transaction do
      @member.save!
      if @member.power != before_power
        Infomation.new(started_at: Time.current, target: :User, user_id: @member.user_id,
                       action: 'MemberUpdate', action_user_id: current_user.id, customer_id: @customer.id).save!
      end
    end
    respond_to do |format|
      format.html { redirect_to members_path(customer_code: @customer.code), notice: t('notice.member.update') }
      format.json { render json: { status: 'OK', notice: t('notice.member.update') }, status: :ok }
    end
  end

  # GET /members/:customer_code/:user_code/delete（ベースドメイン） メンバー解除
  # def delete
  # end

  # DELETE /members/:customer_code/:user_code（ベースドメイン） メンバー解除(処理)
  # DELETE /members/:customer_code/:user_code.json（ベースドメイン） メンバー解除API
  def destroy
    ActiveRecord::Base.transaction do
      Infomation.new(started_at: Time.current, target: :User, user_id: @member.user_id,
                     action: 'MemberDestroy', action_user_id: current_user.id, customer_id: @customer.id).save!
      @member.destroy!
    end
    respond_to do |format|
      format.html { redirect_to members_url, notice: t('notice.member.destroy') }
      format.json { render json: { status: 'OK', notice: t('notice.member.destroy') }, status: :ok }
    end
  end

  private

  # 未所属/存在しないメンバーへのアクセス禁止
  def not_found_outside_member
    @member = Member.where(customer_id: @customer.id)
                    .eager_load(:user).where(users: { code: params[:user_code] }).first
    return if @customer.present?
    return render json: { error: t('errors.messages.user.code_error') }, status: :not_found if request.format.json?

    head :not_found
  end

  # 招待権限がない顧客へのアクセス禁止
  def alert_before_create_power
    if !@customer.member.first.create_power?
      key = 'alert.member.not_create_power.admin'
    elsif current_user.destroy_reserved?
      key = 'alert.user.destroy_reserved'
    else
      return
    end
    return render json: { error: t(key) }, status: :forbidden if request.format.json?

    redirect_to members_path(customer_code: params[:customer_code]), alert: t(key)
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
    return render json: { error: t(key) }, status: :forbidden if request.format.json?

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
    return render json: { error: t(key) }, status: :forbidden if request.format.json?

    redirect_to members_path(customer_code: params[:customer_code]), alert: t(key)
  end
end
