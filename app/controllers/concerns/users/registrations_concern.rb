# frozen_string_literal: true

module Users::RegistrationsConcern
  extend ActiveSupport::Concern

  private

  def set_invitation
    @code = params[:code]
    @invitation = nil
    return if @code.blank?

    @invitation = Invitation.where(code: @code).first
    return if @invitation.present? && @invitation.status == :active
    return render './error', locals: { alert: t('alert.invitation.notfound') }, status: :not_found if format_html?

    render './failure', locals: { alert: t('alert.invitation.notfound') }, status: :not_found
  end

  def get_email(target_params)
    return @invitation.email if @invitation.email.present?
    return if target_params[:email_local].blank?

    domain = @invitation.domains_array.include?(target_params[:email_domain]) ? target_params[:email_domain] : nil
    "#{target_params[:email_local]}@#{domain}"
  end

  def create_invitation_members(user)
    insert_datas = []
    invitation_ids = []
    space_ids = []
    now = Time.current
    member = Member.new(user: user, created_at: now, updated_at: now)

    if @invitation.present?
      if @invitation.email.present?
        # メールアドレスで招待
        insert_datas.push(member.attributes.symbolize_keys.merge(space_id: @invitation.space_id, power: @invitation.power,
                                                                 invitationed_user_id: @invitation.created_user_id, invitationed_at: @invitation.created_at))
        invitation_ids.push(@invitation.id)
      else
        # URLで招待
        invitationed_user = @invitation.last_updated_user.present? ? @invitation.last_updated_user : @invitation.created_user
        insert_datas.push(member.attributes.symbolize_keys.merge(space_id: @invitation.space_id, power: @invitation.power,
                                                                 invitationed_user_id: invitationed_user.id, invitationed_at: now))
      end
      space_ids.push(@invitation.space_id)
    end

    # 他でメールアドレスで招待
    invitations = Invitation.where(email: user.email).order(updated_at: :DESC) # NOTE: 同じスペースで複数有効な場合は更新日時が新しい方を優先する
    invitations.each do |invitation|
      invitation_ids.push(invitation.id) if invitation.email_joined_at.blank?
      next if invitation.status != :active || space_ids.include?(invitation.space_id)

      insert_datas.push(member.attributes.symbolize_keys.merge(space_id: invitation.space_id, power: invitation.power,
                                                               invitationed_user_id: invitation.created_user_id, invitationed_at: invitation.created_at))
      space_ids.push(invitation.space_id)
    end

    Member.insert_all!(insert_datas) if insert_datas.present?
    Invitation.where(id: invitation_ids).update_all(email_joined_at: now, last_updated_user_id: nil, updated_at: now) if invitation_ids.present?
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[code name email_local email_domain])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
  end
end
