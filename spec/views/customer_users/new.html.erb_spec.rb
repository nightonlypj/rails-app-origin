require 'rails_helper'

RSpec.describe 'customer_users/new', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  let!(:customer) { FactoryBot.create(:customer) }
  before { assign(:customer_user, FactoryBot.build(:customer_user, customer_id: customer.id, user_id: user.id, power: 1)) }

  it 'renders new customer_user form' do
    render
    assert_select 'form[action=?][method=?]', customer_users_path, 'post' do
      assert_select 'input[name=?]', 'customer_user[customer_id]'
      assert_select 'input[name=?]', 'customer_user[user_id]'
      assert_select 'input[name=?]', 'customer_user[power]'
    end
  end
end
