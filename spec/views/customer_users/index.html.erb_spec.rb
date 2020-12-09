require 'rails_helper'

RSpec.describe 'customer_users/index', type: :view do
  before(:each) do
    assign(:customer_users, [
             CustomerUser.create!(
               customer: nil,
               user: nil,
               power: 2
             ),
             CustomerUser.create!(
               customer: nil,
               user: nil,
               power: 2
             )
           ])
  end

  it 'renders a list of customer_users' do
    render
    assert_select 'tr>td', text: nil.to_s, count: 2
    assert_select 'tr>td', text: nil.to_s, count: 2
    assert_select 'tr>td', text: 2.to_s, count: 2
  end
end
