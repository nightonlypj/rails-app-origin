require 'rails_helper'

RSpec.describe 'invitations/edit', type: :view do
  before(:each) do
    @invitation = assign(:invitation, Invitation.create!)
  end

  it 'renders the edit invitation form' do
    render

    assert_select 'form[action=?][method=?]', invitation_path(@invitation), 'post' do
    end
  end
end
