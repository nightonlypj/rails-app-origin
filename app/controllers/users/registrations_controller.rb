# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include Users::RegistrationsConcern
  prepend_before_action :authenticate_scope!, only: %i[edit update image_update image_destroy delete destroy undo_delete undo_destroy]
  before_action :redirect_response_destroy_reserved, only: %i[edit update image_update image_destroy delete destroy]
  before_action :redirect_response_not_destroy_reserved, only: %i[undo_delete undo_destroy]
  before_action :configure_sign_up_params, only: %i[create]
  before_action :configure_account_update_params, only: %i[update]

  # GET /users/sign_up アカウント登録
  # def new
  #   super
  # end

  # POST /users/sign_up アカウント登録(処理)
  def create
    params[:user][:code] = create_unique_code(User, 'code', "Users::RegistrationsController.create #{params[:user]}")
    ActiveRecord::Base.transaction do
      super
      flash[:alert] = resource.errors[:code].first if resource.errors[:code].present?
      resource.send_confirmation_instructions if resource.errors.blank? # Tips: devise_token_auth導入後、送信されなくなった為
    end
  end

  # GET /users/edit 登録情報変更
  # def edit
  #   super
  # end

  # PUT /users/edit 登録情報変更(処理)
  def update
    # Tips: 存在するメールアドレスの場合はエラーにする
    if resource.email != params[:user][:email] && User.find_by(email: params[:user][:email]).present?
      resource.errors.add(:email, t('activerecord.errors.models.user.attributes.email.taken'))
      return render :edit
    end

    super
  end

  # POST /users/image/update 画像変更(処理)
  def image_update
    if params.blank? || params[:user].blank?
      resource.errors.add(:image, t('errors.messages.image_update_blank'))
      return render :edit
    end

    @user = User.find(resource.id)
    if @user.update(params.require(:user).permit(:image))
      redirect_to edit_user_registration_path, notice: t('notice.user.image_update')
    else
      render :edit
    end
  end

  # POST /users/image/destroy 画像削除(処理)
  def image_destroy
    @user = User.find(resource.id)
    @user.remove_image!
    @user.save!
    redirect_to edit_user_registration_path, notice: t('notice.user.image_destroy')
  end

  # GET /users/delete アカウント削除
  # def delete
  # end

  # POST /users/delete アカウント削除(処理)
  def destroy
    # resource.destroy
    resource.set_destroy_reserve
    UserMailer.with(user: resource).destroy_reserved.deliver_now

    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroy_reserved
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /users/undo_delete アカウント削除取り消し
  # def undo_delete
  # end

  # POST /users/undo_delete アカウント削除取り消し(処理)
  def undo_destroy
    resource.set_undo_destroy_reserve
    UserMailer.with(user: resource).undo_destroy_reserved.deliver_now

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

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end
end
