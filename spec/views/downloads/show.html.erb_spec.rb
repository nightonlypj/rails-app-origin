require 'rails_helper'

RSpec.describe 'downloads/show', type: :view do
  before(:each) do
    @download = assign(:download, Download.create!)
  end

  it 'renders attributes in <p>' do
    render
  end
end
