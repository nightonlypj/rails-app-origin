require 'rails_helper'

RSpec.describe 'users/registrations/undo_delete', type: :view do
  next if Settings.api_only_mode

  include_context 'ログイン処理', :destroy_reserved
  before_all { @resource = user }

  context do
    it '対象の送信先と項目が含まれる' do
      render
      assert_select 'form[action=?][method=?]', undo_destroy_user_registration_path, 'post' do
        assert_select 'button[type=?]', 'submit'
      end
    end
  end
end
