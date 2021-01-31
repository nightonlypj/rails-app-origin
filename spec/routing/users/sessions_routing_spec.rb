require 'rails_helper'

RSpec.describe Users::SessionsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/users/sign_in').to route_to('users/sessions#new')
    end
    it 'routes to #create' do
      expect(post: '/users/sign_in').to route_to('users/sessions#create')
    end
    it 'routes to #destroy' do
      expect(delete: '/users/sign_out').to route_to('users/sessions#destroy')
      expect(get: '/users/sign_out').to route_to('users/sessions#destroy')
    end
  end
end
