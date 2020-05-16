require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  let!(:admin_user) { create(:admin_user) }

  describe 'GET /admin' do
    context '未ログイン' do
      it 'returns a 302 response' do
        get '/admin'
        expect(response).to have_http_status(302)
      end
    end

    context 'ログイン中' do
      before do
        sign_in admin_user
      end
      it 'returns a 200 response' do
        get '/admin'
        expect(response).to have_http_status(200)
      end
    end
  end
end
