require 'rails_helper'

RSpec.describe 'spaces/edit', type: :view do
  before(:each) do
    @space = assign(:space, Space.create!)
  end

  it 'renders the edit space form' do
    render

    assert_select 'form[action=?][method=?]', space_path(@space), 'post' do
    end
  end
end
