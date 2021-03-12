class RegistrationController < ApplicationController
  before_action :redirect_base_domain_response, only: %i[new]
  before_action :not_found_sub_domain_response, only: %i[create]
  before_action :redirect_response_invalid_invitation_token
  before_action :redirect_response_already_sign_in

  # GET /registration/member（ベースドメイン） メンバー登録
  # def new
  # end

  # POST /registration/member（ベースドメイン） メンバー登録(処理)
  # POST /registration/member.json（ベースドメイン） メンバー登録API
  def create
    @user.assign_attributes(params.require(:user).permit(:name, :password, :password_confirmation))
    @user.valid?
    if @user.errors.any?
      respond_to do |format|
        format.html { return render :new }
        format.json { return render json: { status: 'NG', error: @user.errors.messages }, status: :unprocessable_entity }
      end
    end

    completed_at = Time.current
    @user.assign_attributes(invitation_token: nil, invitation_completed_at: completed_at)
    members = Member.where(user_id: @user.id)
    ActiveRecord::Base.transaction do
      @user.skip_password_change_notification! # Tips: パスワード変更完了メールを送らない
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

  # 不正な招待トークンの場合、リダイレクトしてメッセージを表示
  def redirect_response_invalid_invitation_token
    if params[:invitation_token].blank?
      respond_to do |format|
        format.html { return redirect_to user_signed_in? ? root_path : new_user_session_path, alert: t('alert.user.invitation_token.blank') }
        format.json { return render json: { error: t('alert.user.invitation_token.blank') }, status: :forbidden }
      end
    end

    @user = User.find_by(invitation_token: params[:invitation_token])
    if @user.blank? || @user.invitation_completed_at.present?
      respond_to do |format|
        format.html { return redirect_to user_signed_in? ? root_path : new_user_session_path, alert: t('alert.user.invitation_token.invalid') }
        format.json { return render json: { error: t('alert.user.invitation_token.invalid') }, status: :forbidden }
      end
    end

    @user.name = nil # Tips: ダミーを消す為
  end

  # ログイン中の場合、リダイレクトしてメッセージを表示
  def redirect_response_already_sign_in
    return unless user_signed_in?

    respond_to do |format|
      format.html { redirect_to root_path, alert: t('alert.user.invitation_token.already_sign_in') }
      format.json { render json: { error: t('alert.user.invitation_token.already_sign_in') }, status: :forbidden }
    end
  end
end
