require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  # GET / RailsAdmin
  describe 'GET /admin' do
    context '未ログイン' do
      it 'ログインにリダイレクト' do
        get '/admin'
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
    context 'ログイン中' do
      include_context 'ログイン処理'
      it 'ログインにリダイレクト' do
        get '/admin'
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end
    context 'ログイン中（管理者）' do
      include_context 'ログイン処理（管理者）'
      it '成功ステータス' do
        get '/admin'
        expect(response).to be_successful
      end
    end
  end
end
