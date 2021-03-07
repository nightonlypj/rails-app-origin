require 'rails_helper'

RSpec.describe 'spaces/new', type: :view do
  before do
    @customer = Customer.new
    @space = Space.new
    @join_customers = Customer.all
  end

  it 'renders new space form' do
    render
    assert_select 'form[action=?][method=?]', create_space_path, 'post' do
      assert_select 'input[name=?]', 'space[customer][create_flag]'
      assert_select 'select[name=?]', 'space[customer][code]'
      assert_select 'input[name=?]', 'space[customer][name]'
      assert_select 'input[name=?]', 'space[subdomain]'
      assert_select 'input[name=?]', 'space[public_flag]'
      assert_select 'input[name=?]', 'space[name]'
      assert_select 'input[name=?]', 'space[purpose]'
      assert_select 'input[name=?]', 'space[image]'
      assert_select 'input[name=?]', 'commit'
    end
  end
end
