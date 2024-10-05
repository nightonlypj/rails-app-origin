require 'rails_helper'

RSpec.describe 'downloads/new', type: :view do
  before_all do
    @model = :member
    user = FactoryBot.create(:user)
    @space = FactoryBot.create(:space, created_user: user)
    @current_member = FactoryBot.create(:member, space: @space, user:)
    @enable_target = ['all']
    @items = t("items.#{@model}")

    output_items = @items.stringify_keys.keys
    @download = Download.new(output_items:)
  end

  it '対象の送信先と項目が含まれる' do
    render
    assert_select 'form[action=?][method=?]', create_download_path, 'post' do
      assert_select 'input[name=?]', 'download[model]'
      assert_select 'input[name=?]', 'download[space_code]'
      assert_select 'input[name=?]', 'download[search_params]'
      assert_select 'input[name=?]', 'download[select_items]'
      assert_select 'input[name=?]', 'download[target]', Download.targets.count
      assert_select 'input[name=?]', 'download[format]', Download.formats.count
      assert_select 'input[name=?]', 'download[char_code]', Download.char_codes.count
      assert_select 'input[name=?]', 'download[newline_code]', Download.newline_codes.count
      @items.each_key do |key|
        assert_select 'input[name=?]', "download[output_items_#{key}]"
      end
      assert_select 'input[type=?]', 'button'
    end
  end
end
