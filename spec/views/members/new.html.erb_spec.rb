require 'rails_helper'

RSpec.describe 'members/new', type: :view do
  before do
    @customer = FactoryBot.create(:customer)
    @member = Member.new
    @user = User.new
  end

  it 'renders new member form' do
    render
    assert_select 'form[action=?][method=?]', create_member_path(customer_code: @customer.code), 'post' do
      assert_select 'input[name=?]', 'member[user][email]'
      assert_select 'input[name=?]', 'member[power]'
      assert_select 'input[name=?]', 'commit'
    end
  end
end
