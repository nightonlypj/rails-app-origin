require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  # GET /users/sign_up アカウント登録
  describe 'GET /users/sign_up' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get new_user_registration_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get new_user_registration_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_registration_path}")
      end
    end
  end

  # POST /users アカウント登録(処理)
  describe 'POST /users' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        post user_registration_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        post user_registration_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/edit 登録情報変更
  describe 'GET /users/edit' do
    include_context 'ログイン処理'
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get edit_user_registration_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get edit_user_registration_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{edit_user_registration_path}")
      end
    end
  end

  # PUT /users 登録情報変更(処理)
  describe 'PUT /users' do
    include_context 'ログイン処理'
    context 'ベースドメイン' do
      it 'renders a successful response' do
        put user_registration_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        put user_registration_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # DELETE /users アカウント削除(処理)
  describe 'DELETE /users' do
    include_context 'ログイン処理'
    context 'ベースドメイン' do
      it 'ログインにリダイレクト' do
        delete user_registration_path, headers: base_headers
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        delete user_registration_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end
end
