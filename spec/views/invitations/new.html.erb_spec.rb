require 'rails_helper'

RSpec.describe 'invitations/new', type: :view do
  before_all do
    @space = FactoryBot.create(:space)
    @invitation = Invitation.new
  end

  it '対象の送信先と項目が含まれる' do
    render
    assert_select 'form[action=?][method=?]', create_invitation_path(@space.code), 'post' do
      assert_select 'textarea[name=?]', 'invitation[domains]'
      assert_select 'input[name=?]', 'invitation[power]'
      assert_select 'input[name=?]', 'invitation[ended_date]'
      assert_select 'input[name=?]', 'invitation[ended_time]'
      assert_select 'input[name=?]', 'invitation[memo]'
      assert_select 'input[type=?]', 'button'
    end
  end
end
