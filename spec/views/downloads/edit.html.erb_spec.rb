require 'rails_helper'

RSpec.describe 'downloads/edit', type: :view do
  before(:each) do
    @download = assign(:download, Download.create!)
  end

  it 'renders the edit download form' do
    render

    assert_select 'form[action=?][method=?]', download_path(@download), 'post' do
    end
  end
end
