require 'rails_helper'

RSpec.describe 'users/registrations/edit', type: :view do
  # テスト内容
  shared_examples_for '入力項目' do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', update_user_registration_path, 'post' do
        assert_select 'input[name=?]', 'user[name]'
        assert_select 'input[name=?]', 'user[email]'
        assert_select 'input[name=?]', 'user[password]'
        assert_select 'input[name=?]', 'user[password_confirmation]'
        assert_select 'input[name=?]', 'user[current_password]'
        assert_select 'input[name=?]', 'commit'
      end
      assert_select 'form[action=?][method=?]', update_user_image_registration_path, 'post' do # 画像アップロード
        assert_select 'input[name=?]', 'user[image]'
        assert_select 'input[name=?]', 'commit'
      end
      assert_select 'form[action=?][method=?]', delete_user_image_registration_path, 'post' do # 画像削除
        assert_select 'input[type=?]', 'submit'
      end
    end
  end

  shared_examples_for 'メール確認済み表示' do
    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{delete_user_registration_path}\"") # アカウント削除
    end
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("href=\"#{new_user_confirmation_path}\"") # メールアドレス確認
    end
  end
  shared_examples_for 'メールアドレス変更中表示' do
    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{delete_user_registration_path}\"") # アカウント削除
      expect(rendered).to include("href=\"#{new_user_confirmation_path}\"") # メールアドレス確認
    end
  end

  # テストケース
  context 'ログイン中（メール確認済み）' do
    include_context 'ログイン処理'
    before { @resource = user }
    it_behaves_like '入力項目'
    it_behaves_like 'メール確認済み表示'
  end
  context 'ログイン中（メールアドレス変更中）' do
    include_context 'ログイン処理', :email_changed
    before { @resource = user }
    it_behaves_like '入力項目'
    it_behaves_like 'メールアドレス変更中表示'
  end
end
