require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'login' do
    before { login_user user }
  end

  context '未ログイン' do
    it 'ログインのパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(new_user_session_path)}\"")
    end
    it 'アカウント登録のパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(new_user_registration_path)}\"")
    end
  end

  context 'ログイン中' do
    include_context 'login'
    it 'ログインユーザーのメールアドレスが含まれる' do
      render
      expect(rendered).to match(user.email)
    end
    it 'ユーザー編集のパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(edit_user_registration_path)}\"")
    end
    it 'ログアウトのパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(destroy_user_session_path)}\"")
    end
  end

  shared_context 'subdomain' do
    before do
      @use_space = FactoryBot.create(:space)
    end
  end

  shared_examples_for 'サブドメイン' do
    it 'スペース名が含まれる' do
      render
      expect(rendered).to match(Regexp.escape(@use_space.name))
    end
    it 'スペース編集のパスが含まれる' do
      render
      expect(rendered).to match("\"#{Regexp.escape(edit_space_path(@use_space))}\"")
    end
  end

  context '未ログイン' do
    include_context 'subdomain'
    it_behaves_like 'サブドメイン'
  end

  context 'ログイン中' do
    include_context 'login'
    include_context 'subdomain'
    it_behaves_like 'サブドメイン'
  end
end
