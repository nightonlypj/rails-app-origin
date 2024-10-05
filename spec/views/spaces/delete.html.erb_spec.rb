require 'rails_helper'

RSpec.describe 'spaces/delete', type: :view do
  include_context 'ログイン処理'
  before_all { @space = FactoryBot.create(:space) }

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', destroy_space_path(code: @space.code), 'post' do
        assert_select 'button[type=?]', 'submit'
      end
    end

    it '対象のパスが含まれる' do
      render
      expect(rendered).to include("href=\"#{edit_space_path(code: @space.code)}\"") # スペース設定変更
    end
  end
end
