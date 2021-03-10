require 'rails_helper'

RSpec.describe 'layouts/application', type: :view do
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
    # it 'ログインユーザーの氏名が含まれない' do # Tips: 未ログインの為、対象なし
    # end
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
    it 'ログインユーザーの氏名が含まれる' do
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

  shared_examples_for '削除予約表示' do
    it 'アカウント削除取り消しのパスが含まれる' do
      render
      expect(rendered).to include("\"#{delete_undo_user_registration_path}\"")
    end
  end
  shared_examples_for '削除予約非表示' do
    it 'アカウント削除取り消しのパスが含まれない' do
      render
      expect(rendered).not_to include("\"#{delete_undo_user_registration_path}\"")
    end
  end

  # テストケース
  context '未ログイン' do
    it_behaves_like '未ログイン表示'
    it_behaves_like '削除予約非表示'
  end
  context 'ログイン中' do
    include_context 'ログイン処理'
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約非表示'
  end
  context 'ログイン中（削除予約済み）' do
    include_context 'ログイン処理', true
    it_behaves_like 'ログイン中表示'
    it_behaves_like '削除予約表示'
  end
end
