require 'rails_helper'

RSpec.describe 'spaces/new', type: :view do
  before(:each) do
    assign(:space, Space.new)
  end

  it 'renders new space form' do
    render

    assert_select 'form[action=?][method=?]', spaces_path, 'post' do
    end
  end
end
