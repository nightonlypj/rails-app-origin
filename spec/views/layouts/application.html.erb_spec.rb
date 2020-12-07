require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
  shared_context 'スペース情報作成' do
    before { @request_space = FactoryBot.create(:space) }
  end

  # テスト内容
  shared_examples_for '未ログイン表示' do
    it 'ログインのパスが含まれる' do
      render
      expect(rendered).to include("\"#{new_user_session_path}\"")
    end
    it 'アカウント登録のパスが含まれる' do
      render
      expect(rendered).to include("\"#{new_user_registration_path}\"")
    end
    it '登録情報変更のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{edit_user_registration_path}\"")
    end
    it 'ログアウトのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{destroy_user_session_path}\"")
    end
  end
  shared_examples_for 'ログイン中表示' do
    it 'ログインのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{new_user_session_path}\"")
    end
    it 'アカウント登録のパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{new_user_registration_path}\"")
    end
    it 'ログインユーザーの名前が含まれる' do
      render
      expect(rendered).to include(user.name)
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

  shared_examples_for 'スペース情報あり' do
    it 'スペース名が含まれる' do
      render
      expect(rendered).to include(@request_space.name)
    end
    it 'スペース編集のパスが含まれる' do
      render
      expect(rendered).to include("\"#{edit_space_path}\"")
    end
  end

  # テストケース
  context '未ログイン' do
    it_behaves_like '未ログイン表示'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'ログイン中表示'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', true
    it_behaves_like 'ログイン中表示'
  end

  context '未ログイン' do
    include_context 'スペース情報作成'
    it_behaves_like 'スペース情報あり'
    it_behaves_like '未ログイン表示'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    include_context 'スペース情報作成'
    it_behaves_like 'スペース情報あり'
    it_behaves_like 'ログイン中表示'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', true
    include_context 'スペース情報作成'
    it_behaves_like 'スペース情報あり'
    it_behaves_like 'ログイン中表示'
  end
end
