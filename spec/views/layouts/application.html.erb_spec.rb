require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { login_user user }
  end

  shared_context 'スペース情報作成' do
    before { @use_space = FactoryBot.create(:space) }
  end

  shared_examples_for '未ログインのレスポンス' do
    it 'ログインのパスが含まれる' do
      render
      expect(rendered).to include("\"#{new_user_session_path}\"")
    end
    it 'アカウント登録のパスが含まれる' do
      render
      expect(rendered).to include("\"#{new_user_registration_path}\"")
    end
    it 'ユーザー編集のパスが含まない' do
      render
      expect(rendered).not_to include("\"#{edit_user_registration_path}\"")
    end
    it 'ログアウトのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{destroy_user_session_path}\"")
    end
  end
  shared_examples_for 'ログイン中のレスポンス' do
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
    it 'ユーザー編集のパスが含まれる' do
      render
      expect(rendered).to include("\"#{edit_user_registration_path}\"")
    end
    it 'ログアウトのパスが含まれる' do
      render
      expect(rendered).to include("\"#{destroy_user_session_path}\"")
    end
  end

  shared_examples_for 'スペース情報あり' do
    it 'スペース名が含まれる' do
      render
      expect(rendered).to include(@use_space.name)
    end
    it 'スペース編集のパスが含まれる' do
      render
      expect(rendered).to include("\"#{edit_space_path(@use_space)}\"")
    end
  end

  context '未ログイン' do
    it_behaves_like '未ログインのレスポンス'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'ログイン中のレスポンス'
  end

  context '未ログイン' do
    include_context 'スペース情報作成'
    it_behaves_like 'スペース情報あり'
    it_behaves_like '未ログインのレスポンス'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    include_context 'スペース情報作成'
    it_behaves_like 'スペース情報あり'
    it_behaves_like 'ログイン中のレスポンス'
  end
end
