require 'rails_helper'

RSpec.describe 'members/edit', type: :view do
  before_all do
    @space = FactoryBot.create(:space)
    @current_member = FactoryBot.create(:member, :admin, space: @space, user: @space.created_user)
    @member = FactoryBot.create(:member, :admin, space: @space)
  end

  it '対象の送信先と項目が含まれる' do
    render
    assert_select 'form[action=?][method=?]', update_member_path(@space.code, @member.user.code), 'post' do
      assert_select 'input[name=?]', 'member[power]'
      assert_select 'input[type=?]', 'button'
    end
  end
end
