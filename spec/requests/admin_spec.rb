require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  let!(:admin_user) { create(:admin_user) }

  describe 'GET /admin' do
    context '未ログイン' do
      it 'renders a redirect response' do
        get '/admin'
        expect(response).to be_redirect
      end
    end

    context 'ログイン中' do
      before do
        sign_in admin_user
      end
      it 'renders a successful response' do
        get '/admin'
        expect(response).to be_successful
      end
    end
  end
end
