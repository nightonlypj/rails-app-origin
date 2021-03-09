require 'rails_helper'

RSpec.describe 'members/edit', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  before do
    @customer = FactoryBot.create(:customer)
    @member = assign(:member, FactoryBot.create(:member, customer_id: @customer.id, user_id: user.id, power: :Owner))
  end

  it 'renders the edit member form' do
    render
    assert_select 'form[action=?][method=?]', update_member_path(customer_code: @customer.code, user_code: @member.user.code), 'post' do
      assert_select 'input[name=?]', 'member[power]'
      assert_select 'input[name=?]', 'commit'
    end
  end
end
