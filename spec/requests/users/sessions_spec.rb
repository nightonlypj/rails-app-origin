require 'rails_helper'

RSpec.describe 'Users::Sessions', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  # GET /users/sign_in ログイン
  describe 'GET /users/sign_in' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get new_user_session_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get new_user_session_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_session_path}")
      end
    end
  end

  # POST /users/sign_in ログイン(処理)
  describe 'POST /users/sign_in' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        post user_session_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        post user_session_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # DELETE /users/sign_out ログアウト(処理)
  describe 'DELETE /users/sign_out' do
    include_context 'ログイン処理'
    context 'ベースドメイン' do
      it 'ログインにリダイレクト' do
        delete destroy_user_session_path, headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        delete destroy_user_session_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end
end
