require 'rails_helper'

RSpec.describe 'registration/new.html.erb', type: :view do
  before do
    @user = User.new
  end

  it 'renders new user form' do
    render
    assert_select 'form[action=?][method=?]', create_member_registration_path, 'post' do
      assert_select 'input[name=?]', 'user[name]'
      assert_select 'input[name=?]', 'user[password]'
      assert_select 'input[name=?]', 'user[password_confirmation]'
      assert_select 'input[name=?]', 'commit'
    end
  end
end
