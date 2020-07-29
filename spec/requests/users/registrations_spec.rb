require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let!(:valid_attributes) { FactoryBot.attributes_for(:user) }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  # POST /users アカウント登録(処理)
  describe 'POST /users' do
    context '有効なパラメータ' do
      it 'ログインにリダイレクト' do
        post user_registration_path, params: { user: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  # GET /users/delete アカウント削除
  describe 'GET /users/delete' do
    context '未ログイン' do
      it 'ログインにリダイレクト' do
        get users_delete_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it 'renders a successful response' do
        get users_delete_path
        expect(response).to be_successful
      end
    end
  end
end
