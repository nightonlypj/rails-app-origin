require 'rails_helper'

RSpec.describe 'Holidays', type: :request do
  describe 'GET /index' do
    it 'returns http success' do
      get '/holidays/index'
      expect(response).to have_http_status(:success)
    end
  end
end
