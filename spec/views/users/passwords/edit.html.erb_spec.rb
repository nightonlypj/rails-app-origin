require 'rails_helper'

RSpec.describe 'users/passwords/edit', type: :view do
  before do
    @resource = User.new
    params[:reset_password_token] = SecureRandom.uuid
  end

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[method=?][action=?]', 'post', update_user_password_path(reset_password_token: params[:reset_password_token]) do
        assert_select 'input[name=?]', 'user[password]'
        assert_select 'input[name=?]', 'user[password_confirmation]'
        assert_select 'input[name=?]', 'commit'
      end
    end

    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{new_user_session_path}\"") # ログイン
      expect(rendered).to include("href=\"#{new_user_registration_path}\"") # アカウント登録
      expect(rendered).to include("href=\"#{new_user_confirmation_path}\"") # メールアドレス確認
      expect(rendered).to include("href=\"#{new_user_unlock_path}\"") # アカウントロック解除
    end
    it '対象のパスが含まれない' do
      render
      expect(rendered).not_to include("href=\"#{new_user_password_path}\"") # パスワード再設定
    end
  end
end
