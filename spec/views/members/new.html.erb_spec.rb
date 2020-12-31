require 'rails_helper'

RSpec.describe 'members/new', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  before do
    @customer = FactoryBot.create(:customer)
    assign(:member, FactoryBot.build(:member, customer_id: @customer.id, user_id: user.id, power: :Owner))
  end

  it 'renders new member form' do
    render
    assert_select 'form[action=?][method=?]', members_path(customer_code: @customer.code), 'post' do
      assert_select 'input[name=?]', 'member[customer_id]'
      assert_select 'input[name=?]', 'member[user_id]'
      assert_select 'select[name=?]', 'member[power]'
    end
  end
end
