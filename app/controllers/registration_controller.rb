class RegistrationController < ApplicationController
  before_action :not_found_json_sub_domain_response
  before_action :redirect_base_domain_response, only: %i[new]
  before_action :not_found_sub_domain_response, only: %i[create]
  before_action :alert_already_sign_in
  before_action :alert_invitation_token

  # GET /registration/sign_up（ベースドメイン） メンバー登録
  # def new
  # end

  # POST /registration/sign_up（ベースドメイン） メンバー登録(処理)
  # POST /registration/sign_up.json（ベースドメイン） メンバー登録API
  def create
    @user.assign_attributes(params.require(:user).permit(:name, :password, :password_confirmation))
    @user.valid?
    if @user.errors.present?
      respond_to do |format|
        format.html { return render :new }
        format.json { return render json: { status: 'NG', errors: @user.errors }, status: :unprocessable_entity }
      end
    end

    completed_at = Time.current
    @user.assign_attributes(invitation_token: nil, invitation_completed_at: completed_at)
    members = Member.where(user_id: @user.id)
    ActiveRecord::Base.transaction do
      @user.save!
      members.each do |member|
        if member.invitation_user_id.present?
          Infomation.new(started_at: completed_at, target: :User, user_id: member.invitation_user_id,
                         action: 'RegistrationCreate', action_user_id: @user.id, customer_id: member.customer_id).save!
        end
      end
    end
    sign_in(User, @user)
    respond_to do |format|
      format.html { redirect_to root_path, notice: t('notice.registration.create') }
      format.json { render json: { status: 'OK', notice: t('notice.registration.create') }, status: :ok }
    end
  end

  private

  # ログイン中のアクセス禁止
  def alert_already_sign_in
    redirect_to root_path, alert: t('alert.user.invitation_token.already_sign_in') if user_signed_in?
  end

  # 不正な招待トークンでのアクセス禁止
  def alert_invitation_token
    return redirect_to new_user_session_path, alert: t('alert.user.invitation_token.blank') if params[:invitation_token].blank?

    @user = User.find_by(invitation_token: params[:invitation_token])
    return redirect_to new_user_session_path, alert: t('alert.user.invitation_token.invalid') if @user.blank?

    @user.name = nil # Tips: ダミーを消す為
  end
end
