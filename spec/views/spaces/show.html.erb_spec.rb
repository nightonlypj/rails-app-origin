require 'rails_helper'

RSpec.describe 'spaces/show', type: :view do
  before(:each) do
    @space = assign(:space, Space.create!)
  end

  it 'renders attributes in <p>' do
    render
  end
end
