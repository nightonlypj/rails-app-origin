require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }

  # GET /users/confirmation/new メールアドレス確認メール再送
  describe 'GET /users/confirmation/new' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get '/users/confirmation/new', headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get '/users/confirmation/new', headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain_link']}#{new_user_confirmation_path}")
      end
    end
  end

  # POST /users/confirmation メールアドレス確認メール再送(処理)
  describe 'POST /users/confirmation' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        post '/users/confirmation', headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        post '/users/confirmation', headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/confirmation メールアドレス確認(処理)
  describe 'GET /users/confirmation' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get '/users/confirmation', headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get '/users/confirmation', headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain_link']}#{user_confirmation_path}")
      end
    end
  end
end
