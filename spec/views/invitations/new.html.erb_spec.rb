require 'rails_helper'

RSpec.describe 'invitations/new', type: :view do
  before(:each) do
    assign(:invitation, Invitation.new)
  end

  it 'renders new invitation form' do
    render

    assert_select 'form[action=?][method=?]', invitations_path, 'post' do
    end
  end
end
