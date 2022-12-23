require 'rails_helper'

RSpec.describe 'invitations/show', type: :view do
  before(:each) do
    @invitation = assign(:invitation, Invitation.create!)
  end

  it 'renders attributes in <p>' do
    render
  end
end
