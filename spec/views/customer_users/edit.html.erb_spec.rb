require 'rails_helper'

RSpec.describe 'customer_users/edit', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  let!(:customer) { FactoryBot.create(:customer) }
  before { @customer_user = assign(:customer_user, FactoryBot.create(:customer_user, customer_id: customer.id, user_id: user.id, power: 1)) }

  it 'renders the edit customer_user form' do
    render
    assert_select 'form[action=?][method=?]', customer_user_path(@customer_user), 'post' do
      assert_select 'input[name=?]', 'customer_user[customer_id]'
      assert_select 'input[name=?]', 'customer_user[user_id]'
      assert_select 'input[name=?]', 'customer_user[power]'
    end
  end
end
