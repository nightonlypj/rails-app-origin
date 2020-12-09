require 'rails_helper'

RSpec.describe 'customer_users/new', type: :view do
  before(:each) do
    assign(:customer_user, CustomerUser.new(
                             customer: nil,
                             user: nil,
                             power: 1
                           ))
  end

  it 'renders new customer_user form' do
    render

    assert_select 'form[action=?][method=?]', customer_users_path, 'post' do
      assert_select 'input[name=?]', 'customer_user[customer_id]'

      assert_select 'input[name=?]', 'customer_user[user_id]'

      assert_select 'input[name=?]', 'customer_user[power]'
    end
  end
end
