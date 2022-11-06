module MembersDownloadConcern
  extend ActiveSupport::Concern
  include MembersConcern

  private

  def members_file(output_items)
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
          data.push(member_value(member, output_item))
        end
        result += data.to_csv(col_sep: @download.col_sep, row_sep: @download.row_sep)
      end
      break if page >= members.total_pages

      page += 1
    end

    result
  end
end
