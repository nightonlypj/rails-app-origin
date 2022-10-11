require 'rails_helper'

RSpec.describe 'downloads/index', type: :view do
  before(:each) do
    assign(:downloads, [
             Download.create!,
             Download.create!
           ])
  end

  it 'renders a list of downloads' do
    render
  end
end
