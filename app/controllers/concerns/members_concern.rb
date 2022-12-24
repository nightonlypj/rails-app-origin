module MembersConcern
  extend ActiveSupport::Concern

  private

  SORT_COLUMN = {
    'user.name' => 'users.name',
    'user.email' => 'users.email',
    'power' => 'members.power',
    'invitationed_user.name' => 'invitationed_users_members.name',
    'invitationed_at' => 'members.invitationed_at',
    'last_updated_user.name' => 'last_updated_users_members.name',
    'last_updated_at' => 'members.updated_at'
  }.freeze

  def get_value(member, output_item)
    case output_item
    when 'user.name'
      member.user.name
    when 'user.email'
      member.user.email
    when 'power'
      member.power_i18n
    when 'invitationed_user.name'
      member.invitationed_user&.name
    when 'invitationed_at'
      I18n.l(member.invitationed_at, default: nil)
    when 'last_updated_user.name'
      member.last_updated_user&.name
    when 'last_updated_at'
      I18n.l(member.last_updated_at, default: nil)
    else
      raise "output_item not found.(#{output_item})"
    end
  end

  def set_params_index(search_params = params, sort_only = false)
    @power = {}
    @powers = []
    if sort_only
      @text = nil
      @option = nil

      Member.powers.each do |_key, value|
        @power[value] = true
      end
    else
      @text = search_params[:text]&.slice(..(255 - 1))
      @option = search_params[:option] == '1'

      Member.powers.each do |key, value|
        if power_include_key?(search_params[:power], key)
          @power[value] = true
          @powers.push(key)
        end
      end
    end

    @sort = SORT_COLUMN.include?(search_params[:sort]) ? search_params[:sort] : 'invitationed_at'
    @desc = search_params[:desc] != '0'
  end

  def power_include_key?(power, key)
    return !power.instance_of?(String) if power.blank?

    power.instance_of?(String) ? power.split(',').include?(key) : power[key] == '1'
  end

  def members_select(codes)
    Member.where(space: @space).includes(:user).where(user: { code: codes }).eager_load(:user, :invitationed_user, :last_updated_user)
          .order(SORT_COLUMN[@sort] + (@desc ? ' DESC' : ''), id: :desc)
  end

  def members_search
    Member.where(space: @space, power: @power.keys).search(@text, @current_member).eager_load(:user, :invitationed_user, :last_updated_user)
          .order(SORT_COLUMN[@sort] + (@desc ? ' DESC' : ''), id: :desc)
  end

  # ダウンロードファイルのデータ作成
  def member_file_data(output_items)
    search_params = @download.search_params.present? ? eval(@download.search_params).symbolize_keys : {}
    set_params_index(search_params, @download.target.to_sym != :search)

    result = ''
    base_members = @download.target.to_sym == :select ? members_select(eval(@download.select_items)) : members_search
    page = 1
    loop do
      members = base_members.page(page).per(Settings['job_members_limit'])
      members.each do |member|
        data = []
        output_items.each do |output_item|
          data.push(get_value(member, output_item))
        end
        result += data.to_csv(col_sep: @download.col_sep, row_sep: @download.row_sep)
      end
      break if page >= members.total_pages

      page += 1
    end

    result
  end
end
