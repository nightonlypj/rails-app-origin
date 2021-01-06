require 'rails_helper'

RSpec.describe 'Registrations', type: :request do
  describe 'GET /new' do
    it 'returns http success' do
      get '/registration/new'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /create' do
    it 'returns http success' do
      get '/registration/create'
      expect(response).to have_http_status(:success)
    end
  end
end
