require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let!(:valid_attributes) { FactoryBot.attributes_for(:user) }

  # POST /users アカウント登録(処理)
  describe 'POST /users' do
    context '有効なパラメータ' do
      it 'ログインにリダイレクト' do
        post user_registration_path, params: { user: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
