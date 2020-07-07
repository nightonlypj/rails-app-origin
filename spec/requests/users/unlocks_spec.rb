require 'rails_helper'

RSpec.describe 'Users::Unlocks', type: :request do
  let!(:base_headers) { { 'Host' => Settings['base_domain'] } }
  let!(:space_headers) { { 'Host' => "space.#{Settings['base_domain']}" } }

  # GET /users/unlock/new アカウントロック解除メール再送
  describe 'GET /users/unlock/new' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get '/users/unlock/new', headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get '/users/unlock/new', headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain_link']}#{new_user_unlock_path}")
      end
    end
  end

  # POST /users/unlock アカウントロック解除メール再送(処理)
  describe 'POST /users/unlock' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        post '/users/unlock', headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'renders a not found response' do
        post '/users/unlock', headers: space_headers
        expect(response).to be_not_found
      end
    end
  end

  # GET /users/unlock アカウントロック解除(処理)
  describe 'GET /users/unlock' do
    context 'ベースドメイン' do
      it 'renders a successful response' do
        get '/users/unlock', headers: base_headers
        expect(response).to be_successful
      end
    end
    context 'サブドメイン' do
      it 'ベースドメインにリダイレクト' do
        get '/users/unlock', headers: space_headers
        expect(response).to redirect_to("//#{Settings['base_domain_link']}#{user_unlock_path}")
      end
    end
  end
end
