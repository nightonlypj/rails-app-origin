module MembersConcern
  extend ActiveSupport::Concern

  private

  MEMBERS_SORT_COLUMN = {
    'user.name' => 'users.name',
    'user.email' => 'users.email',
    'power' => 'power',
    'invitation_user.name' => 'invitation_users_members.name',
    'invitationed_at' => 'invitationed_at'
  }.freeze

  def member_value(member, output_item)
    case output_item
    when 'user.name'
      member.user.name
    when 'user.email'
      member.user.email
    when 'power'
      member.power_i18n
    when 'invitation_user.name'
      member.invitation_user&.name
    when 'invitationed_at'
      member.invitationed_at.present? ? I18n.l(member.invitationed_at) : nil
    else
      raise 'output_item not found.'
    end
  end

  def set_params_index(target_params = params, sort_only = false)
    @power = {}
    if sort_only
      @text = nil
      @option = nil

      Member.powers.each do |_key, value|
        @power[value] = true
      end
    else
      @text = target_params[:text]&.slice(..(255 - 1))
      @option = target_params[:option] == '1'

      Member.powers.each do |key, value|
        @power[value] = true if target_params[key] != '0'
      end
    end

    @sort = MEMBERS_SORT_COLUMN.include?(target_params[:sort]) ? target_params[:sort] : 'invitationed_at'
    @desc = target_params[:desc] != '0'
  end

  def members_select(codes)
    Member.where(space: @space).includes(:user).where(user: { code: codes }).eager_load(:user, :invitation_user)
          .order(MEMBERS_SORT_COLUMN[@sort] + (@desc ? ' DESC' : ''), id: :desc)
  end

  def members_search
    Member.where(space: @space, power: @power.keys).search(@text, @current_member).eager_load(:user, :invitation_user)
          .order(MEMBERS_SORT_COLUMN[@sort] + (@desc ? ' DESC' : ''), id: :desc)
  end
end
