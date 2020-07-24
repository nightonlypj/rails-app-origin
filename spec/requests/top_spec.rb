require 'rails_helper'

RSpec.describe 'Top', type: :request do
  let!(:user) { FactoryBot.create(:user) }
  shared_context 'ログイン処理' do
    before { sign_in user }
  end

  # GET / トップページ
  describe 'GET /' do
    shared_examples_for 'レスポンス' do
      it 'renders a successful response' do
        get root_path
        expect(response).to be_successful
      end
    end

    context '未ログイン' do
      it_behaves_like 'レスポンス'
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it_behaves_like 'レスポンス'
    end
  end
end
