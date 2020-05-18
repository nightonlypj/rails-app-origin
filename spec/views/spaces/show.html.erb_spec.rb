require 'rails_helper'

RSpec.describe 'spaces/show', type: :view do
  before(:each) do
    @space = assign(:space, Space.create!(
                              subdomain: 'Subdomain',
                              name: 'Name'
                            ))
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Subdomain/)
    expect(rendered).to match(/Name/)
  end
end
