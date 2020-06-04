require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  let!(:admin_user) { FactoryBot.create(:admin_user) }
  shared_context 'ログイン処理' do
    before { sign_in admin_user }
  end

  describe 'GET /admin' do
    context '未ログイン' do
      it 'renders a redirect response' do
        get '/admin'
        expect(response).to be_redirect
      end
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it 'renders a successful response' do
        get '/admin'
        expect(response).to be_successful
      end
    end
  end
end
