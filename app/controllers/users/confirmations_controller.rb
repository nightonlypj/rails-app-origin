# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  before_action :redirect_base_domain_response, only: %i[new show]
  before_action :not_found_sub_domain_response, only: %i[create]

  # GET /users/confirmation/new（ベースドメイン） メールアドレス確認[メール再送]
  # def new
  #   super
  # end

  # POST /users/confirmation/new（ベースドメイン） メールアドレス確認[メール再送](処理)
  def create
    if params.present? && params[:user].present?
      user = User.find_by(email: params[:user][:email])
      if user.present? && user.invitation_requested_at.present? && user.invitation_completed_at.blank?
        member = Member.where(customer_id: user.invitation_customer_id, user_id: user.id).first
        customer = member.present? ? Customer.find_by(id: member.customer_id) : nil
        invitation_user = member.present? ? User.find_by(id: member.invitation_user_id) : nil
        UserMailer.with(user: user, member: member, customer: customer, invitation_user: invitation_user).member_create.deliver_now
        return redirect_to new_user_session_path, notice: t('notice.user.invitation_token.send_instructions')
      end
    end

    super
  end

  # GET /users/confirmation（ベースドメイン） メールアドレス確認(処理)
  def show
    return redirect_to new_user_session_path, alert: already_confirmed_message if already_confirmed?(params[:confirmation_token])
    return redirect_to new_user_confirmation_path, alert: invalid_token_message unless valid_confirmation_token?(params[:confirmation_token])

    super
  end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end

  private

  # メールアドレス確認済みメッセージを返却
  def already_confirmed_message
    t('errors.messages.already_confirmed')
  end

  # トークンエラーメッセージを返却
  def invalid_token_message
    t('activerecord.errors.models.user.attributes.confirmation_token.invalid')
  end
end
