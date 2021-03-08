require 'rails_helper'

RSpec.describe 'customers/edit', type: :view do
  before do
    @customer = assign(:customer, FactoryBot.create(:customer))
  end

  it 'renders the edit customer form' do
    render
    assert_select 'form[action=?][method=?]', update_customer_path(customer_code: @customer.code), 'post' do
      assert_select 'input[name=?]', 'customer[name]'
      assert_select 'input[name=?]', 'commit'
    end
  end
end
