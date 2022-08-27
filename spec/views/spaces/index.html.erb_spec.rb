require 'rails_helper'

RSpec.describe 'spaces/index', type: :view do
  before(:each) do
    assign(:spaces, [
             Space.create!,
             Space.create!
           ])
  end

  it 'renders a list of spaces' do
    render
  end
end
