require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  context '未ログイン' do
    it 'ログインのパスが含まれる' do
      render
      expect(rendered).to include("\"#{new_user_session_path}\"")
    end
    it 'アカウント登録のパスが含まれる' do
      render
      expect(rendered).to include("\"#{new_user_registration_path}\"")
    end
    it '登録情報変更のパスが含まない' do
      render
      expect(rendered).not_to include("\"#{edit_user_registration_path}\"")
    end
    it 'ログアウトのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{destroy_user_session_path}\"")
    end
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it 'ログインのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{new_user_session_path}\"")
    end
    it 'アカウント登録のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{new_user_registration_path}\"")
    end
    it 'ログインユーザーのメールアドレスが含まれる' do
      render
      expect(rendered).to include(user.email)
    end
    it '登録情報変更のパスが含まれる' do
      render
      expect(rendered).to include("\"#{edit_user_registration_path}\"")
    end
    it 'ログアウトのパスが含まれる' do
      render
      expect(rendered).to include("\"#{destroy_user_session_path}\"")
    end
  end
end
