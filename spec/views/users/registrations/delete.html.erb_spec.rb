require 'rails_helper'

RSpec.describe 'users/registrations/delete', type: :view do
  include_context 'ログイン処理'
  before { @resource = user }

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', destroy_user_registration_path, 'post' do
        assert_select 'input[type=?]', 'submit'
      end
    end

    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{edit_user_registration_path}\"") # 登録情報変更
    end
  end
end
