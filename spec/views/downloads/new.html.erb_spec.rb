require 'rails_helper'

RSpec.describe 'downloads/new', type: :view do
  before(:each) do
    assign(:download, Download.new)
  end

  it 'renders new download form' do
    render

    assert_select 'form[action=?][method=?]', downloads_path, 'post' do
    end
  end
end
