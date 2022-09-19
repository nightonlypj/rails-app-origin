require 'rails_helper'

RSpec.describe 'admin_users/unlocks/new', type: :view do
  before_all { @resource = AdminUser.new }

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', create_admin_user_unlock_path, 'post' do
        assert_select 'input[name=?]', 'admin_user[email]'
        assert_select 'input[name=?]', 'commit'
      end
    end

    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{new_admin_user_session_path}\"") # ログイン
      expect(rendered).to include("href=\"#{new_admin_user_password_path}\"") # パスワード再設定
    end
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("href=\"#{new_admin_user_unlock_path}\"") # アカウントロック解除
    end
  end
end
