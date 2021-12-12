require 'rails_helper'

RSpec.describe 'admin_users/passwords/edit', type: :view do
  before do
    @resource = AdminUser.new
    params[:reset_password_token] = SecureRandom.uuid
  end

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[method=?][action=?]', 'post', update_admin_user_password_path(reset_password_token: params[:reset_password_token]) do
        assert_select 'input[name=?][value=?]', '_method', 'put'
        assert_select 'input[name=?]', 'admin_user[password]'
        assert_select 'input[name=?]', 'admin_user[password_confirmation]'
        assert_select 'input[name=?]', 'commit'
      end
    end

    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{new_admin_user_session_path}\"") # ログイン
      expect(rendered).to include("href=\"#{new_admin_user_unlock_path}\"") # アカウントロック解除
    end
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("href=\"#{new_admin_user_password_path}\"") # パスワード再設定
    end
  end
end
