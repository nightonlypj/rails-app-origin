require 'rails_helper'

RSpec.describe 'customer_users/edit', type: :view do
  before(:each) do
    @customer_user = assign(:customer_user, CustomerUser.create!(
                                              customer: nil,
                                              user: nil,
                                              power: 1
                                            ))
  end

  it 'renders the edit customer_user form' do
    render

    assert_select 'form[action=?][method=?]', customer_user_path(@customer_user), 'post' do
      assert_select 'input[name=?]', 'customer_user[customer_id]'

      assert_select 'input[name=?]', 'customer_user[user_id]'

      assert_select 'input[name=?]', 'customer_user[power]'
    end
  end
end
