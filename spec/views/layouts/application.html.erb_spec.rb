require 'rails_helper'

RSpec.describe 'layouts/application.html.erb', type: :view do
  let!(:user) { create(:user) }

  context '未ログイン' do
    it 'Log inのパスが含まれる' do
      render
      expect(rendered).to match(new_user_session_path)
    end
    it 'Sign upのパスが含まれる' do
      render
      expect(rendered).to match(new_user_registration_path)
    end
  end

  context 'ログイン中' do
    before do
      login_user user
    end
    it 'ログインユーザーのメールアドレスが含まれる' do
      render
      expect(rendered).to match(user.email)
    end
    it 'Edit Userのパスが含まれる' do
      render
      expect(rendered).to match(edit_user_registration_path)
    end
    it 'Log outのパスが含まれる' do
      render
      expect(rendered).to match(destroy_user_session_path)
    end
  end
end
