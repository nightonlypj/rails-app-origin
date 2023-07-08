require 'rails_helper'

RSpec.describe 'members/index', type: :view do
  before_all do
    @space = FactoryBot.create(:space)
    @current_member = FactoryBot.create(:member, space: @space, user: @space.created_user)
    @members = Member.page(1).per(2)
    @text = nil
    @option = false
    @power = {}
    @checked = {
      active: true,
      destroy: true
    }
  end

  it '対象の送信先と項目が含まれる' do
    render
    assert_select 'form[action=?][method=?]', members_path(@space.code), 'get' do
      assert_select 'input[name=?]', 'text'
      assert_select 'button[type=?]', 'submit'
      assert_select 'input[name=?]', 'option'
      Member.powers.each do |key, _value|
        assert_select 'input[name=?]', "power[#{key}]"
      end
      assert_select 'input[name=?]', 'active'
      assert_select 'input[name=?]', 'destroy'
    end
  end
end
