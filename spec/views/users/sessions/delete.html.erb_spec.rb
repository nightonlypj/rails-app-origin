require 'rails_helper'

RSpec.describe 'users/sessions/delete', type: :view do
  include_context 'ログイン処理'
  before_all { @resource = user }

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', destroy_user_session_path, 'post' do
        assert_select 'input[type=?]', 'submit'
      end
    end

    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("\"#{root_path}\"") # トップページ
    end
  end
end
