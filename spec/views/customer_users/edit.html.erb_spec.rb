require 'rails_helper'

RSpec.describe 'customer_users/edit', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  before do
    @customer = FactoryBot.create(:customer)
    @customer_user = assign(:customer_user, FactoryBot.create(:customer_user, customer_id: @customer.id, user_id: user.id, power: :Owner))
  end

  it 'renders the edit customer_user form' do
    render
    assert_select 'form[action=?][method=?]', customer_user_path(customer_code: @customer.code, user_code: @customer_user.user.code), 'post' do
      assert_select 'input[name=?]', 'customer_user[power]'
    end
  end
end
