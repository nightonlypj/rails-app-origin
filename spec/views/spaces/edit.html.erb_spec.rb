require 'rails_helper'

RSpec.describe 'spaces/edit', type: :view do
  let!(:customer) { FactoryBot.create(:customer) }
  before { @space = assign(:space, FactoryBot.create(:space, customer_id: customer.id)) }

  it 'renders the edit space form' do
    render
    assert_select 'form[action=?][method=?]', update_space_path, 'post' do
      assert_select 'input[name=?]', 'space[subdomain]'
      assert_select 'input[name=?]', 'space[name]'
      assert_select 'input[name=?]', 'commit'
    end
  end
end
