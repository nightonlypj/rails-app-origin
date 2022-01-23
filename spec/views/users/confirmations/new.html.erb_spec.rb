require 'rails_helper'

RSpec.describe 'users/confirmations/new', type: :view do
  before { @resource = User.new }

  # テスト内容
  shared_examples_for '入力項目' do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', create_user_confirmation_path, 'post' do
        assert_select 'input[name=?]', 'user[email]'
        assert_select 'input[name=?]', 'commit'
      end
    end
  end

  shared_examples_for '未ログイン表示' do
    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{new_user_session_path}\"") # ログイン
      expect(rendered).to include("href=\"#{new_user_registration_path}\"") # アカウント登録
      expect(rendered).to include("href=\"#{new_user_password_path}\"") # パスワード再設定
      expect(rendered).to include("href=\"#{new_user_unlock_path}\"") # アカウントロック解除
    end
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("href=\"#{new_user_confirmation_path}\"") # メールアドレス確認
    end
  end
  shared_examples_for 'ログイン中表示' do
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("href=\"#{new_user_session_path}\"") # ログイン
      expect(rendered).not_to include("href=\"#{new_user_registration_path}\"") # アカウント登録
      expect(rendered).not_to include("href=\"#{new_user_password_path}\"") # パスワード再設定
      expect(rendered).not_to include("href=\"#{new_user_unlock_path}\"") # アカウントロック解除
      expect(rendered).not_to include("href=\"#{new_user_confirmation_path}\"") # メールアドレス確認
    end
  end

  # テストケース
  context '未ログイン' do
    it_behaves_like '入力項目'
    it_behaves_like '未ログイン表示'
  end
  context 'ログイン中（メール確認済み）' do
    include_context 'ログイン処理'
    it_behaves_like '入力項目'
    it_behaves_like 'ログイン中表示'
  end
  context 'ログイン中（メールアドレス変更中）' do
    include_context 'ログイン処理', :user_email_changed
    it_behaves_like '入力項目'
    it_behaves_like 'ログイン中表示'
  end
end
