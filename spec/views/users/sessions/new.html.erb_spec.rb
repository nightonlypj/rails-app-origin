require 'rails_helper'

RSpec.describe 'users/sessions/new', type: :view do
  before_all { @resource = User.new }

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', create_user_session_path, 'post' do
        assert_select 'input[name=?]', 'user[email]'
        assert_select 'input[name=?]', 'user[password]'
        assert_select 'input[name=?]', 'user[remember_me]'
        assert_select 'input[name=?]', 'commit'
      end
    end

    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{new_user_registration_path}\"") # アカウント登録
      expect(rendered).to include("href=\"#{new_user_password_path}\"") # パスワード再設定
      expect(rendered).to include("href=\"#{new_user_confirmation_path}\"") # メールアドレス確認
      expect(rendered).to include("href=\"#{new_user_unlock_path}\"") # アカウントロック解除
    end
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("href=\"#{new_user_session_path}\"") # ログイン
    end
  end
end
