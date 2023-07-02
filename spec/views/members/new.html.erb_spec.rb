require 'rails_helper'

RSpec.describe 'members/new', type: :view do
  before_all do
    @space = FactoryBot.create(:space)
    @current_member = FactoryBot.create(:member, space: @space, user: @space.created_user)
    @member = Member.new
  end

  it '対象の送信先と項目が含まれる' do
    render
    assert_select 'form[action=?][method=?]', create_member_path(@space.code), 'post' do
      assert_select 'textarea[name=?]', 'member[emails]'
      assert_select 'input[name=?]', 'member[power]'
      assert_select 'input[type=?]', 'button'
    end
  end
end
