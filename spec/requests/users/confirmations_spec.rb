require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }

  # GET /users/confirmation/new メールアドレス確認メール再送
  describe 'GET /users/confirmation/new' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get new_user_confirmation_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get new_user_confirmation_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{new_user_confirmation_path}")
      end
    end
  end

  # POST /users/confirmation メールアドレス確認メール再送(処理)
  describe 'POST /users/confirmation' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        post user_confirmation_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        post user_confirmation_path, headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  describe 'GET /users/confirmation' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get user_confirmation_path, headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get user_confirmation_path, headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain']}#{user_confirmation_path}")
      end
    end
  end
end
