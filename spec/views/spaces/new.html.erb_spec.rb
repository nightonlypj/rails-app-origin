require 'rails_helper'

RSpec.describe 'spaces/new', type: :view do
  before(:each) { assign(:space, FactoryBot.build(:space)) }

  it 'renders new space form' do
    render
    assert_select 'form[action=?][method=?]', create_space_path, 'post' do
      assert_select 'input[name=?]', 'space[subdomain]'
      assert_select 'input[name=?]', 'space[name]'
      assert_select 'input[name=?]', 'commit'
    end
  end
end
