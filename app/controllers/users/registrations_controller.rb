# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  prepend_before_action :authenticate_scope!, only: %i[edit update image_update image_destroy delete destroy undo_delete undo_destroy]
  before_action :redirect_response_destroy_reserved, only: %i[edit update image_update image_destroy delete destroy]
  before_action :redirect_response_not_destroy_reserved, only: %i[undo_delete undo_destroy]

  # GET /users/sign_up アカウント登録
  # def new
  #   super
  # end

  # POST /users アカウント登録(処理)
  def create
    # ユーザーコード作成
    try_count = 1
    loop do
      params[:user][:code] = Digest::MD5.hexdigest(SecureRandom.uuid)
      break if User.find_by(code: params[:user][:code]).blank?

      if try_count < 10
        logger.warn("[WARN](#{try_count})Not unique code: Users::RegistrationsController.create #{params[:user]}")
      elsif try_count >= 10
        logger.error("[ERROR](#{try_count})Not unique code: Users::RegistrationsController.create #{params[:user]}")
        break
      end
      try_count += 1
    end

    super
  end

  # GET /users/edit 登録情報変更
  # def edit
  #   super
  # end

  # PUT /users 登録情報変更(処理)
  # def update
  #   super
  # end

  # PUT /users/image 画像変更(処理)
  def image_update
    if params.blank? || params[:user].blank?
      resource.errors.add(:image, t('errors.messages.image_update_blank'))
      return render :edit
    end

    @user = User.find(current_user.id)
    return render :edit unless @user.update(params.require(:user).permit(:image))

    redirect_to edit_user_registration_path, notice: t('notice.user.image_update')
  end

  # DELETE /users/image 画像削除(処理)
  def image_destroy
    @user = User.find(current_user.id)
    @user.remove_image!
    if @user.save
      redirect_to edit_user_registration_path, notice: t('notice.user.image_destroy')
    else
      redirect_to edit_user_registration_path, notice: t('errors.messages.image_destroy_error')
    end
  end

  # GET /users/delete アカウント削除
  # def delete
  # end

  # DELETE /users アカウント削除(処理)
  def destroy
    resource.set_destroy_reserve
    UserMailer.with(user: current_user).destroy_reserved.deliver_now

    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroy_reserved
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /users/undo_delete アカウント削除取り消し
  # def undo_delete
  # end

  # DELETE /users/undo_delete アカウント削除取り消し(処理)
  def undo_destroy
    resource.set_undo_destroy_reserve
    UserMailer.with(user: current_user).undo_destroy_reserved.deliver_now

    set_flash_message! :notice, :undo_destroy_reserved
    redirect_to root_path
  end

  # GET /users/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[code name])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  private

  # 削除予約済みの場合、リダイレクトしてメッセージを表示
  def redirect_response_destroy_reserved
    redirect_to root_path, notice: t('notice.user.destroy_reserved') if current_user.destroy_reserved?
  end

  # 削除予約済みでない場合、リダイレクトしてメッセージを表示
  def redirect_response_not_destroy_reserved
    redirect_to root_path, notice: t('notice.user.not_destroy_reserved') unless current_user.destroy_reserved?
  end
end
