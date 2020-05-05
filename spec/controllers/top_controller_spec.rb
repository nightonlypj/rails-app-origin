require 'rails_helper'

RSpec.describe TopController, type: :controller do
  render_views

  describe 'GET #index/トップページにアクセス' do
    it 'returns http success/HTTPステータスコードが200' do
      get :index
      expect(response).to have_http_status(:success)
    end
    it 'ページ中にHello World!が含まれる' do
      get :index
      expect(response.body).to match(/Hello World!/)
    end
  end
end
